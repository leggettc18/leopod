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

		private Sqlite.Database db; // the Database

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

		/*
         * Checks to see if the local database file exists
         */
        public bool check_database_exists () {
            File file = File.new_for_path (db_location);
            return file.query_exists ();
        }

        /*
         * Returns true if the library is empty, false otherwise.
         */
        public bool empty () {
            return podcasts.size == 0;
        }

		/*
		 * Adds a podcast to the database and the active podcast list
		 */
		public bool add_podcast (Podcast podcast) throws LeapodLibraryError {
		    info ("Podcast %s is being added to the library", podcast.name);

		    // Set all but the most recent episode as played
		    if (podcast.episodes.size > 0) {
		        for (int i = 0; i < podcasts.size - 1; i++) {
		            podcast.episodes[i].status = EpisodeStatus.PLAYED;
		        }
		    }

		    string podcast_path = local_library_path + "%s".printf (
		        podcast.name.replace ("%27", "'").replace ("%", "_")
		    );

		    // Create a directory for downloads and artwork caching
		    GLib.DirUtils.create_with_parents (podcast_path, 0775);

		    // Locally cache the album art if necessary
		    try {
		        // Don't user the coverart_path getter, use the remote_uri
		        GLib.File remote_art = GLib.File.new_for_uri (podcast.remote_art_uri);
		        if (remote_art.query_exists ()) {
		            // If the remote art exists, set path for new file and create object for the local file
		            string art_path = podcast_path + "/" + remote_art.get_basename ().replace ("%", "_");
		            GLib.File local_art = GLib.File.new_for_path (art_path);

		            if (!local_art.query_exists ()) {
		                // Cache the art
		                remote_art.copy (local_art, FileCopyFlags.NONE);
		            }
		            // Mark the local path on the podcast
		            podcast.local_art_uri = "file://" + art_path;
		        }
		    } catch (Error e) {
		        error ("unable to save a local copy of album art. %s", e.message);
		    }

		    // Add the podcast
		    if (write_podcast_to_database (podcast)) {
		        // Add it to the local arraylist
		        podcasts.add (podcast);

		        // Fill in the podcast's episodes
		        foreach (Episode episode in podcast.episodes) {
		            episode.podcast_uri = podcast.feed_uri;
		            write_episode_to_database (episode);
		        }
		    } else {
		        warning ("failed adding podcast '%s'.", podcast.name);
		    }
		    return true;
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

		/*
		 * Inserts or replaces a podcast in the database
		 */
		public bool write_podcast_to_database (Podcast podcast) {
		    // Convert content_type enum to string
		    string content_type_text;
		    if (podcast.content_type == MediaType.AUDIO) {
		        content_type_text = "audio";
		    } else if (podcast.content_type == MediaType.VIDEO) {
		        content_type_text = "video";
		    } else {
		        content_type_text = "unknown";
		    }

		    //Convert license enum to string
		    string license_text;
            if (podcast.license == License.CC) {
                license_text = "cc";
            } else if (podcast.license == License.PUBLIC) {
                license_text = "public";
            } else if (podcast.license == License.RESERVED) {
                license_text = "reserved";
            } else {
                license_text = "unknown";
            }

            string query = "INSERT OR REPLACE INTO Podcast" +
                " (name, feed_uri, album_art_url, album_art_local_uri, description, content_type, license) " +
                " VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7);";

            Sqlite.Statement stmt;
            int ec = db.prepare_v2 (query, query.length, out stmt);

            if (ec != Sqlite.OK) {
                warning (
                    "unable to prepare podcast statment. %d: %s",
                    db.errcode (),
                    db.errmsg ()
                );
                return false;
            }

            stmt.bind_text (1, podcast.name);
            stmt.bind_text (2, podcast.feed_uri);
            stmt.bind_text (3, podcast.remote_art_uri);
            stmt.bind_text (4, podcast.local_art_uri);
            stmt.bind_text (5, podcast.description);
            stmt.bind_text (6, content_type_text);
            stmt.bind_text (7, license_text);

            ec = stmt.step ();

            if (ec != Sqlite.DONE) {
                warning (
                    "unable to insert/update podcast. %d: %s",
                    db.errcode (),
                    db.errmsg ()
                );
                return false;
            }

            return true;
		}

		/*
		 * Insert or Replace an episode in the database
		 */
		public bool write_episode_to_database (Episode episode) {
		    assert (episode.podcast_uri != null && episode.podcast_uri != "");

		    string query = """
		        INSERT OR REPLACE INTO Episode
		        (title, podcast_uri, uri, local_uri, released, description,
		        latest_position, download_status, play_status, guid, link)
		        VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11);
		    """;

		    Sqlite.Statement stmt;
		    int ec = db.prepare_v2(query, query.length, out stmt);

		    if (ec != Sqlite.OK) {
		        warning (
		            "unable to prepare episode insert statment. %d: %s",
		            db.errcode (),
		            db.errmsg ()
		        );
		    }

		    // Convert Enums to their text representations
		    string played_text =
		        (episode.status == EpisodeStatus.PLAYED) ? "played" : "unplayed";
		    string download_text =
		        (episode.current_download_status == DownloadStatus.DOWNLOADED) ? "downloaded" : "not_downloaded";

		    stmt.bind_text (1, episode.title);
		    stmt.bind_text (2, episode.podcast_uri);
		    stmt.bind_text (3, episode.uri);
		    stmt.bind_text (4, episode.local_uri);
		    stmt.bind_int64 (5, episode.datetime_released.to_unix ());
		    stmt.bind_text (6, episode.description);
		    stmt.bind_text (7, episode.last_played_position.to_string ());
		    stmt.bind_text (8, download_text);
		    stmt.bind_text (9, played_text);
		    stmt.bind_text (10, episode.guid);
		    stmt.bind_text (11, episode.link);

		    ec = stmt.step ();

		    if (ec != Sqlite.DONE) {
		        warning (
		            "unable to insert/update episode. %d: %s",
		            db.errcode (),
		            db.errmsg ()
		        );
		        return false;
		    }

		    return true;
		}
	}
}
