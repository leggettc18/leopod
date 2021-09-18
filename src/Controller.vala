/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leapod {
	public class Controller : GLib.Object {
		public MainWindow window = null;
		public Library library = null;
		public MyApp app = null;
		
		public Controller (MyApp app) {
			info ("initializing the controller.");
			this.app = app;
			
			info ("initializing blank library");
			library = new Library ();
			
			info ("initializing the main window");
			window = new MainWindow (this);
			window.set_titlebar (this.app.header_bar);
			info ("showing main window");
			window.show_all ();
			
			window.populate_views_async.begin ((obj, res) => {
			    window.populate_views_async.end (res);
			});
			
		}
		
		public void add_podcast (string podcast_uri) {
		    Podcast podcast = new FeedParser ().get_podcast_from_file (podcast_uri);
		    window.add_podcast(podcast);
		}
	}
}
