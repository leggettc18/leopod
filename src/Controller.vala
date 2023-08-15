/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {
    public class Controller : Object {
        // Objects
        public Application app { get; construct; }

        // Signals
        public signal void playback_status_changed (string status);
        public signal void track_changed (
            string episode_title, string podcast_name, string artwork_uri, uint64 duration
        );
        public signal void update_status_changed (bool currently_updating);

        // Runtime Flags
        public bool first_run { get; private set; default = true; }
        public bool checking_for_updates { get; private set; default = false; }
        public bool currently_repopulating { get; private set; default = false; }
        private bool importing = false;

        // System
        //public Gst.PbUtils.InstallPluginsContext context;

        // References
        public Episode current_episode;

        public Controller (Application app) {
            Object (app: app);
        }

        construct {
            first_run = (!app.library.check_database_exists ());

            if (first_run) {
                app.library.setup_library ();
            }


            //player.eos.connect (window.on_stream_ended);
            //player.additional_plugins_required.connect (window.on_additional_plugins_needed);

            app.player.new_position_available.connect (() => {
                if (app.player.progress > 0) {
                    //player.current_episode.last_played_position = (int) player.get_position ();
                }

                int mins_remaining;
                int secs_remaining;
                int mins_elapsed;
                int secs_elapsed;

                double total_secs_elapsed = (app.player.duration * app.player.progress) / 1000000000;

                mins_elapsed = (int) total_secs_elapsed / 60;
                secs_elapsed = (int) total_secs_elapsed % 60;

                double total_secs_remaining = (app.player.duration / 1000000000) - total_secs_elapsed;

                mins_remaining = (int) total_secs_remaining / 60;
                secs_remaining = (int) total_secs_remaining % 60;

                if (app.player.progress != 0.0) {
                    app.window.playback_box.set_progress (
                        app.player.progress, mins_remaining, secs_remaining, mins_elapsed, secs_elapsed
                    );
                }
            });
        }

        public async void post_creation_sequence () {
            if (first_run) {
                app.window.switch_visible_page (app.window.welcome);
            } else {
                yield app.library.refill_library ();
                if (app.library.empty ()) {
                    app.window.switch_visible_page (app.window.welcome);
                } else {
                    yield on_update_request ();
                    app.window.populate_views ();
                }
            }

            GLib.Timeout.add (300000, () => {
                if (!importing) {
                    on_update_request.begin ((obj, res) => {
                        on_update_request.end (res);
                    });
                }
                return true;
            });
        }

        public void add_podcast (string podcast_uri) {
            try {
                Podcast podcast = new FeedParser ().get_podcast_from_file (podcast_uri);
                app.library.add_podcast.begin (podcast);
                app.window.populate_views ();
            } catch (Error e) {
                error (e.message);
            }
        }

        public async void import_opml (string path) {
            try {
                string[] feeds = new FeedParser ().parse_feeds_from_OPML (path);
                importing = true;
                foreach (string feed in feeds) {
                    yield add_podcast_async (feed);
                }
                importing = false;
            } catch (LeopodLibraryError e) {
                error (e.message);
            }
        }

        private async Podcast download_podcast (string podcast_uri) {
            SourceFunc callback = download_podcast.callback;
            Podcast* podcast = null;
            ThreadFunc<void> run = () => {
                try {
                    podcast = new FeedParser ().get_podcast_from_file (podcast_uri);
                } catch (Error e) {
                    error (e.message);
                }
                Idle.add ((owned) callback);
            };
            new Thread<void> ("download_and_store_podcast", (owned) run);
            yield;
            return podcast;
        }

        public async void add_podcast_async (string podcast_uri) {
            info ("downloading podcast");
            Podcast podcast = yield download_podcast (podcast_uri);
            try {
                info ("adding podcast to library");
                yield app.library.add_podcast (podcast);
            } catch (Error e) {
                error (e.message);
            }
            app.window.populate_views ();
        }

        public async void on_update_request () {
            if (!checking_for_updates) {
                SourceFunc callback = on_update_request.callback;

                ThreadFunc<void> run = () => {
                    checking_for_updates = true;
                    update_status_changed (true);

                    Gee.ArrayList<Episode> new_episodes = new Gee.ArrayList<Episode> ();

                    new_episodes = app.library.check_for_updates ();

                    checking_for_updates = false;
                    update_status_changed (false);

                    int new_episode_count = new_episodes.size;

                    new_episodes = null;

                    if (new_episode_count > 0) {
                        //library.refill_library ();
                        app.window.populate_views_async.begin ((obj, res) => {
                            app.window.populate_views_async.end (res);
                        });
                    }
                    Idle.add ((owned) callback);
                };

                new Thread<void> ("on_update_request", (owned) run);
                yield;
            } else {
                info ("Leopod is already updating.");
            }
        }

        public void play_pause () {
            if (app.player != null) {
                if (app.player.playing) {
                    pause ();
                } else {
                    play ();
                }
            }
        }

        /*
         * Handles play requests and starts media playback using the player
         */
        public void play () {
            if (current_episode != null) {
                app.window.playback_box.show ();
                app.library.mark_episode_as_played (current_episode);

                if (app.player.current_episode != current_episode) {
                    if (app.player.current_episode != null) {
                        info (
                            "Setting last played position of %s: %" + int64.FORMAT,
                            current_episode.title,
                            app.player.get_position ()
                        );
                        app.player.current_episode.last_played_position = app.player.get_position ();
                        app.library.set_episode_playback_position (app.player.current_episode);
                    }
                    app.player.set_episode (current_episode);
                    track_changed (
                        current_episode.title.replace ("%27", "'"),
                        current_episode.parent.name,
                        current_episode.parent.coverart_uri,
                        (uint64) app.player.duration
                    );
                } else {
                    app.player.play ();
                }

                //TODO: handle video content

                //  GLib.Timeout.add (5000, () => {
                //      if (player.duration != 0) {
                //          info ("Last Played Position: %" + int64.FORMAT, current_episode.last_played_position);
                //          player.play ();
                //          if (
                //              current_episode.last_played_position > 0
                //          ) {
                //              player.set_position (current_episode.last_played_position);
                //          }
                //      }
                //      return (player.duration == 0);
                //  });
                playback_status_changed ("Playing");


                app.window.playback_box.set_info_title (
                    current_episode.title.replace ("%27", "'"),
                    current_episode.parent.name.replace ("%27", "'")
                );

                app.window.show ();
            }
        }

        public void pause () {
            if (app.player.playing) {
                app.player.pause ();
                playback_status_changed ("Paused");

                current_episode.last_played_position = app.player.get_position ();
                app.library.set_episode_playback_position (current_episode);

                app.window.playback_box.set_info_title (
                    current_episode.title.replace ("%27", "'"),
                    current_episode.parent.name.replace ("%27", "'")
                );

                app.window.show ();
            }
        }

        public void seek_forward () {
            app.player.seek_forward (10);
        }

        public void seek_backward () {
            app.player.seek_backward (10);
        }
    }
}
