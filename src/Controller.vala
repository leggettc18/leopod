/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {
	public class Controller : GLib.Object {
	    public bool first_run = true;
	    public bool checking_for_updates;
		public MainWindow window = null;
		public Library library = null;
		public MyApp app = null;

		public signal void update_status_changed (bool currently_updating);

		public Controller (MyApp app) {
			info ("initializing the controller.");
			this.app = app;

			info ("initializing blank library");
			library = new Library (this);

			first_run = (!library.check_database_exists ());

			if (first_run) {
			    info ("Setting up library");
			    library.setup_library ();
			} else {
			    info ("Refilling library");
			    library.refill_library ();
			}

			info ("initializing the main window");
			window = new MainWindow (this);
			info ("showing main window");

			post_creation_sequence ();
		}

		private void post_creation_sequence () {
		    if (first_run || library.empty ()) {
		        window.show_all ();
		        window.switch_visible_page (window.welcome);
		    } else {
		    	on_update_request ();
		        window.populate_views ();
		        info ("Showing main window");
		        window.show_all ();
		        info ("switching to all_scrolled view");
		        window.switch_visible_page (window.all_scrolled);
		    }
		}

		public void add_podcast (string podcast_uri) {
		    Podcast podcast = new FeedParser ().get_podcast_from_file (podcast_uri);
		    library.add_podcast (podcast);
		    window.add_podcast_feed(podcast);
		}

		public async void add_podcast_async (string podcast_uri) {
		    SourceFunc callback = add_podcast_async.callback;

            ThreadFunc<void*> run = () => {

                add_podcast (podcast_uri);

                Idle.add ((owned) callback);
                return null;
            };

            new Thread<void*> ("add-podcast", (owned) run);

            yield;
		}

		public void on_update_request () {
		    if (!checking_for_updates) {
		        info ("Checking for updates.");

		        checking_for_updates = true;
		        update_status_changed (true);

		        Gee.ArrayList<Episode> new_episodes = new Gee.ArrayList<Episode> ();

		        var loop = new MainLoop ();
		        library.check_for_updates.begin ((obj, res) => {
		            try {
		                new_episodes = library.check_for_updates.end (res);
		            } catch (Error e) {
		                warning (e.message);
		            }
		            loop.quit ();
		        });
		        loop.run ();

		        checking_for_updates = false;
		        update_status_changed (false);

		        int new_episode_count = new_episodes.size;

		        new_episodes = null;

		        // if (new_episode_count > 0) {
		        //     info ("Repopulating views after update is finished");
		        //     window.populate_views_async ();
		        // }
		    } else {
		        info ("Leopod is already updating.");
		    }
		}
	}
}
