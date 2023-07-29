/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {
	public class Controller : GLib.Object {
	    // Objects
		public MainWindow window = null;
		public Library library = null;
		public MyApp app = null;
		public Player player;

        // Signals
        public signal void playback_status_changed (string status);
        public signal void track_changed (string episode_title, string podcast_name, string artwork_uri, uint64 duration);
		public signal void update_status_changed (bool currently_updating);

		// Runtime Flags
		public bool first_run = true;
	    public bool checking_for_updates = false;
	    public bool currently_repopulating = false;

	    // System
	    //public Gst.PbUtils.InstallPluginsContext context;

	    // References
	    public Episode current_episode;

		public Controller (MyApp app) {
			this.app = app;
			player = Player.get_default (app.args);
			library = new Library (this);

			first_run = (!library.check_database_exists ());

			if (first_run) {
			    library.setup_library ();
			} else {
			    library.refill_library ();
			}

			window = new MainWindow (this);

			window.podcast_delete_requested.connect ((podcast) => {
				library.delete_podcast.begin (podcast, (obj, res) => {
                    library.delete_podcast.end(res);
                });
				//library.refill_library ();
				//window.populate_views ();
			});

			//player.eos.connect (window.on_stream_ended);
			//player.additional_plugins_required.connect (window.on_additional_plugins_needed);

            MPRIS mpris = new MPRIS (this);
            mpris.initialize ();

            player.new_position_available.connect (() => {
                if (player.progress > 0) {
                    //player.current_episode.last_played_position = (int) player.get_position ();
                }

                int mins_remaining;
                int secs_remaining;
                int mins_elapsed;
                int secs_elapsed;

                double total_secs_elapsed = (player.duration * player.progress) / 1000000000;

                mins_elapsed = (int) total_secs_elapsed / 60;
                secs_elapsed = (int) total_secs_elapsed % 60;

                double total_secs_remaining = (player.duration / 1000000000) - total_secs_elapsed;

                mins_remaining = (int) total_secs_remaining / 60;
                secs_remaining = (int) total_secs_remaining % 60;

                if (player.progress != 0.0) {
                    window.playback_box.set_progress (player.progress, mins_remaining, secs_remaining, mins_elapsed, secs_elapsed);
                }
            });

			post_creation_sequence ();
		}

		private void post_creation_sequence () {
		    if (first_run || library.empty ()) {
		        window.show();
		        window.switch_visible_page (window.welcome);
		        window.playback_box.hide ();
		    } else {
		        window.populate_views();
		        info ("Showing main window");
		        window.show();
		        window.playback_box.hide ();
		        info ("switching to all_scrolled view");
		        window.switch_visible_page (window.main_box);
		        on_update_request.begin ((obj, res) => {
                    on_update_request.end (res);
                });
		    }

		    GLib.Timeout.add (300000, () => {
		        on_update_request.begin ((obj, res) => {
                    on_update_request.end (res);
                });
		        return true;
		    });
		}

		public void add_podcast (string podcast_uri) {
            try {
		        Podcast podcast = new FeedParser ().get_podcast_from_file (podcast_uri);
		        library.add_podcast.begin (podcast);
			    window.populate_views ();
            } catch (Error e) {
                error (e.message);
            }
		}

        private async Podcast download_podcast (string podcast_uri) {
            SourceFunc callback = download_podcast.callback;
            Podcast podcast = null;
            ThreadFunc<Podcast> run = () => {
                try {
                    podcast = new FeedParser ().get_podcast_from_file (podcast_uri);
                } catch (Error e) {
                    error (e.message);
                }
                Idle.add ((owned) callback);
                return podcast;
            };
            new Thread<Podcast> ("download_and_store_podcast", (owned) run);
            yield;
            return podcast;
        }

		public async void add_podcast_async (string podcast_uri) {
            SourceFunc callback = add_podcast_async.callback;
            Podcast podcast = yield download_podcast(podcast_uri);
            try {
                yield library.add_podcast (podcast);
            } catch (Error e) {
                error (e.message);
            }
            window.populate_views ();
            Idle.add ((owned) callback);
            yield;
		}

		public async void on_update_request () {
		    if (!checking_for_updates) {
                SourceFunc callback = on_update_request.callback;

                ThreadFunc<void> run = () => {
		            checking_for_updates = true;
		            update_status_changed (true);

		            Gee.ArrayList<Episode> new_episodes = new Gee.ArrayList<Episode> ();

		            new_episodes = library.check_for_updates ();

		            checking_for_updates = false;
		            update_status_changed (false);

		            int new_episode_count = new_episodes.size;

		            new_episodes = null;

		            if (new_episode_count > 0) {
		                //library.refill_library ();
		                window.populate_views_async.begin ((obj, res) => {
                            window.populate_views_async.end (res);
                        });
		            }
                    Idle.add((owned) callback);
                };

                new Thread<void> ("on_update_request", (owned) run);
                yield;
		    } else {
		        info ("Leopod is already updating.");
		    }
		}

		public void play_pause () {
		    if (player != null) {
		        if (player.playing) {
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
		        window.playback_box.show ();
		        library.mark_episode_as_played (current_episode);

		        if (player.current_episode != current_episode) {
		            if (player.current_episode != null) {
						info ("Setting last played position of %s: %" + int64.FORMAT, current_episode.title, player.get_position ());
		                player.current_episode.last_played_position = player.get_position ();
		                library.set_episode_playback_position (player.current_episode);
		            }
					player.set_episode (current_episode);
		            track_changed (current_episode.title.replace ("%27", "'"), current_episode.parent.name, current_episode.parent.coverart_uri, (uint64) player.duration);
		        } else {
                    player.play ();
                }

		        //TODO: handle video content

		        //  GLib.Timeout.add (5000, () => {
		        //  	if (player.duration != 0) {
				//  		info ("Last Played Position: %" + int64.FORMAT, current_episode.last_played_position);
				//  		player.play ();
		        //  		if (
		        //      		current_episode.last_played_position > 0
		        //  		) {
		        //  			player.set_position (current_episode.last_played_position);
		        //  		}
		        //  	}
		        //  	return (player.duration == 0);
		        //  });
                playback_status_changed ("Playing");


		        window.playback_box.set_info_title (
		            current_episode.title.replace ("%27", "'"),
		            current_episode.parent.name.replace ("%27", "'")
		        );

		        window.show();
		    }
		}

		public void pause () {
	        if (player.playing) {
	            player.pause ();
	            playback_status_changed ("Paused");

	            current_episode.last_played_position = player.get_position ();
	            library.set_episode_playback_position (current_episode);

	            window.playback_box.set_info_title (
	                current_episode.title.replace ("%27", "'"),
	                current_episode.parent.name.replace ("%27", "'")
	            );

	            window.show();
	        }
		}

		public void seek_forward () {
		    player.seek_forward (10);
		}

		public void seek_backward () {
		    player.seek_backward (10);
		}
	}
}
