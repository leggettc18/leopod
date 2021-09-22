/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leapod {
	public class Controller : GLib.Object {
	    public bool first_run = true;
		public MainWindow window = null;
		public Library library = null;
		public MyApp app = null;
		
		public Controller (MyApp app) {
			info ("initializing the controller.");
			this.app = app;
			
			info ("initializing blank library");
			library = new Library (this);
			
			first_run = (!library.check_database_exists ());
			
			info ("initializing the main window");
			window = new MainWindow (this);
			window.set_titlebar (this.app.header_bar);
			info ("showing main window");
			
			window.populate_views_async.begin ((obj, res) => {
			    window.populate_views_async.end (res);
			});
			
			post_creation_sequence ();
		}
		
		private void post_creation_sequence () {
		    if (first_run || library.empty ()) {
		        window.show_all ();
		        window.switch_visible_page (window.welcome);
		    } else {
		        window.populate_views ();
		        window.show_all ();
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
	}
}
