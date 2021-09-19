/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leapod {
	
	public errordomain LeapodLibraryError {
	    ADD_ERROR, IMPORT_ERROR, MISSING_URI;
	}
	
	public class Library {
		public Gee.ArrayList<Podcast> podcasts;
		public Controller controller;
		
		public signal void library_loaded ();
		
		public Library (Controller controller) {
		    this.controller = controller;
		    podcasts = new Gee.ArrayList<Podcast> ();
		}
		
		public void populate_library () {
		    info ("Populating Library");
		    podcasts = new Gee.ArrayList<Podcast> ();
		    string[] uris = {
		        "https://latenightlinux.com/feed/mp3", 
		        "https://feeds.fireside.fm/linuxunplugged/rss",
		        "https://feeds.fireside.fm/coder/rss"
		    };
            foreach (string uri in uris) {
                controller.add_podcast_async.begin (uri);
            }
            
            info ("signalling library loaded");
            library_loaded ();
		}
	}
}
