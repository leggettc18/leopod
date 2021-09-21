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
		
		private Sqlite.Database.db // the Database
		
		private string db_location = null;
		private string leapod_config_dir = null;
		private string db_directory = null;
		private string local_library_path;
		
		private LeapodSettings settings;
		
		public signal void library_loaded ();
		
		public Library (Controller controller) {
		    this.controller = controller;
		    
		    leapod_config_dir = 
		        GLib.Environment.get_user_config_dir () + """/leapod""";
		    this.db_directory = leapod_config_dir + """/database""";
		    this.db_location = this.db_directory + """/leapod.db""";
		    
		    podcasts = new Gee.ArrayList<Podcast> ();
		    
		    settings = LeapodSettings.get_default_instance ();
		    
		    // Set the local library directory and replace ~ with absolute path
		    local_library_path = settings.library_location.replace (
		        "~",
		        GLib.Environment.get_home_dir ()
		    );
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
		
		/*
		 * Opens the database connection, creating the database if it does
		 * not exist
		 */
		private int prepare_database () {
		    assert (db_location != null);
		    
		    // Open a database
		    info ("Opening/Creating Database");
		    int ec = Sqlite.Database.open (db_location, out db);
		    if (ec != Sqlite.OK) {
		        stderr.printf (
		            "Can't open database: %d: %s\n", 
		            db.errcode (), db.errmsg ()
		        );
                return -1;
		    }
		    return 0;
		}
		
		/*
		 * Creates Leapod's config directory, establishes a database connection
		 * and initializes the database schema
		 */
		public bool setup_library () {
		    prepare_database ();
		    
		    if (settings.library_location == null) {
		        settings.library_location = 
		            GLib.Environment.get_user_data_dir () + """/leapod""";
		    }
		    local_library_path = settings.library_location.replace (
		        "~",
		        GLib.Environment.get_user_data_dir ()
		    );
		    
		    // If the local library path has been modified, update the setting
		    if (settings.library_location != local_library_path) {
		        settings.library_location = local_library_path;
		    }
		    
		    // Create the local library
		    GLib.DirUtils.create_with_parents (local_library_path, 0775);
		    
		    // Create the leapod folder if it doesn't exist
		    GLib.DirUtils.create_with_parents (db_directory, 0775);
		    
		    create_db_schema ();
		    
		    return true;
		}
		
		/* Initializes the database schema */
		public void create_db_schema () {
		    prepare_database ();
		    
		    string query = """
		        BEGIN TRANSACTION;
		        
		        CREATE TABLE Podcast (
		            name                TEXT                    NOT NULL,
		            feed_uri            TEXT    PRIMARY_KEY     NOT NULL,
		            album_art_url       TEXT,
		            album_art_local_uri TEXT,
		            description         TEXT                    NOT NULL,
		            content_type        TEXT,
		            license             TEXT
		        );
		        
		        CREATE INDEX podcast_name ON Podcast (name);
		        
		        CREATE TABLE Episode (
		            title               TEXT                    NOT NULL,
		            podcast_uri         TEXT                    NOT NULL,
		            uri                 TEXT                    NOT NULL,
		            local_uri           TEXT,
		            released            INT,
		            description         TEXT,
		            latest_position     TEXT,
		            download_status     TEXT,
		            play_status         TEXT,
		            guid                TEXT,
		            link                TEXT
		        );
		        
		        CREATE UNIQUE INDEX episode_guid ON Episode (guid, link, podcast_uri);
		        CREATE INDEX episode_title ON Episode (title);
		        CREATE INDEX episode_released ON Episode (released);
		        
		        PRAGMA user_version = 1;
		        
		        END TRANSACTION;
		    """;
		    
		    int ec = db.exec (query, null);
		    if (ec != Sqlite.OK) {
		        error (
		            "unable to create database schema %d: %s", 
		            db.errcode (), 
		            db.errmsg ()
		        );
		    }
		    
		    return;
		}
	}
}
