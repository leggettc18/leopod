/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

	public errordomain LeopodLibraryError {
	    ADD_ERROR, IMPORT_ERROR, MISSING_URI;
	}

	public class Library {
		public Gee.ArrayList<Podcast> podcasts;
		public Controller controller;

		private Sqlite.Database db; // the Database

		private string db_location = null;
		private string leopod_config_dir = null;
		private string db_directory = null;
		private string local_library_path;

		private GLib.Settings settings;

		public signal void library_loaded ();

		public Library (Controller controller) {
		    this.controller = controller;

		    leopod_config_dir =
		        GLib.Environment.get_user_config_dir () + """/leopod""";
		    this.db_directory = leopod_config_dir + """/database""";
		    this.db_location = this.db_directory + """/leopod.db""";
		    info (db_location);

		    podcasts = new Gee.ArrayList<Podcast> ();

		    settings = new GLib.Settings ("com.github.leggettc18.leopod");

		    info (settings.get_string("library-location"));

		    // Set the local library directory and replace ~ with absolute path
		    local_library_path = settings.get_string("library-location").replace (
		        "~",
		        GLib.Environment.get_home_dir ()
		    );

		    info (local_library_path);
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

        public async Gee.ArrayList<Episode> check_for_updates () {
            SourceFunc callback = check_for_updates.callback;
            Gee.ArrayList<Episode> new_episodes = new Gee.ArrayList<Episode> ();

            FeedParser parser = new FeedParser ();

            ThreadFunc<void*> run = () => {
                foreach (Podcast podcast in podcasts) {
                    int added = -1;
                    if (podcast.feed_uri != null && podcast.feed_uri.length > 4) {
                        info ("updating feed %s", podcast.feed_uri);

                        try {
                            added = parser.update_feed (podcast);
                        } catch (Error e) {
                            warning (
                                "Failed to update feed for podcast: %s. %s",
                                podcast.name, e.message
                            );
                            continue;
                        }
                    }

                    while (added > 0) {
                        int index = podcast.episodes.size - added;

                        new_episodes.add (podcast.episodes[index]);
                        write_episode_to_database (podcast.episodes[index]);
                        added--;
                    }

                    if (added == -1) {
                        critical ("Unable to update podcast due to missing feed url");
                    }
                }
                Idle.add ((owned) callback);
                return null;
            };
            Thread.create<void*> (run, false);

            yield;

            return new_episodes;
        }

        /*
         * Refills the library from the database
         */
        public void refill_library () {
            podcasts.clear ();
            prepare_database ();

            Sqlite.Statement stmt;

            string prepared_query = """
                SELECT * FROM Podcast ORDER BY name;
            """;
            int ec = db.prepare_v2 (prepared_query, prepared_query.length, out stmt);
            if (ec != Sqlite.OK) {
                warning ("%d: %s", db.errcode (), db.errmsg ());
                return;
            }

            while (stmt.step () == Sqlite.ROW) {
                Podcast current = podcast_from_row (stmt);
                podcasts.add (current);
            }

            stmt.reset ();
            foreach (Podcast podcast in podcasts) {
                prepared_query = """
                    SELECT e.*, p.name as parent_podcast_name
                    FROM Episode e
                    LEFT JOIN Podcast p on p.feed_uri = e.podcast_uri
                    WHERE podcast_uri = '%s'
                    ORDER BY e.rowid ASC;
                """.printf (podcast.feed_uri);;
                ec = db.prepare_v2 (prepared_query, prepared_query.length, out stmt);
                if (ec != Sqlite.OK) {
                    warning ("%d: %s", db.errcode (), db.errmsg ());
                    return;
                }

                while (stmt.step () == Sqlite.ROW) {
                    Episode episode = episode_from_row (stmt);
                    episode.parent = podcast;

                    podcast.episodes.add (episode);
                }
                stmt.reset ();
            }
        }

        public Podcast podcast_from_row (Sqlite.Statement stmt) {
            Podcast podcast = new Podcast ();

            for (int i = 0; i < stmt.column_count (); i++) {
                string column_name = stmt.column_name (i) ?? "<none>";
                string val = stmt.column_text (i) ?? "<none>";

                if (column_name == "name") {
                    podcast.name = val;
                } else if (column_name == "feed_uri") {
                    podcast.feed_uri = val;
                } else if (column_name == "album_art_url") {
                    podcast.remote_art_uri = val;
                } else if (column_name == "album_art_local_uri") {
                    podcast.local_art_uri = val;
                } else if (column_name == "description") {
                    podcast.description = val;
                } else if (column_name == "content_type") {
                    if (val == "audio") {
                        podcast.content_type = MediaType.AUDIO;
                    } else if (val == "video") {
                        podcast.content_type = MediaType.VIDEO;
                    } else {
                        podcast.content_type = MediaType.UNKNOWN;
                    }
                } else if (column_name == "license") {
                    if (val == "cc") {
                        podcast.license = License.CC;
                    } else if (val == "public") {
                        podcast.license = License.PUBLIC;
                    } else if (val == "reserved") {
                        podcast.license = License.RESERVED;
                    } else {
                        podcast.license = License.UNKNOWN;
                    }
                }
            }

            return podcast;
        }

        public Episode episode_from_row (Sqlite.Statement stmt) {
            Episode episode = new Episode ();

            for (int i = 0; i < stmt.column_count (); i++) {
                string column_name = stmt.column_name (i) ?? "<none>";
                string val = stmt.column_text (i) ?? "<none>";

                if (column_name == "title") {
                    episode.title = val;
                } else if (column_name == "description") {
                    episode.description = val;
                } else if (column_name == "uri") {
                    episode.uri = val;
                } else if (column_name == "local_uri") {
                    if (val != null) {
                        episode.local_uri = val;
                    }
                } else if (column_name == "released") {
                    episode.datetime_released = new GLib.DateTime.from_unix_local (
                        val.to_int64 ()
                    );
                } else if (column_name == "download_status") {
                    if (val == "downloaded") {
                        episode.current_download_status = DownloadStatus.DOWNLOADED;
                    } else if (val == "not_downloaded") {
                        episode.current_download_status = DownloadStatus.NOT_DOWNLOADED;
                    }
                } else if (column_name == "play_status") {
                    if (val == "played") {
                        episode.status = EpisodeStatus.PLAYED;
                    } else {
                        episode.status = EpisodeStatus.UNPLAYED;
                    }
                } else if (column_name == "latest_position") {
                    int64 position = 0;
                    if (int64.try_parse (val, out position)) {
                        episode.last_played_position = (int)position;
                    }
                } else if (column_name == "parent_podcast_name") {
                    episode.parent = new Podcast.with_name (val);
                } else if (column_name == "podcast_uri") {
                    episode.podcast_uri = val;
                } else if (column_name == "guid") {
                    episode.guid = val;
                } else if (column_name == "link") {
                    episode.link = val;
                }
            }
            return episode;
        }

        /*
         * Downloads and Caches a podcast's album art if it doesn't
         * already exist.
         */
         public void cache_album_art (Podcast podcast) {
            string podcast_path = local_library_path + "/%s".printf (
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
         }

		/*
		 * Adds a podcast to the database and the active podcast list
		 */
		public bool add_podcast (Podcast podcast) throws LeopodLibraryError {
		    info ("Podcast %s is being added to the library", podcast.name);

		    // Set all but the most recent episode as played
		    if (podcast.episodes.size > 0) {
		        for (int i = 0; i < podcast.episodes.size - 1; i++) {
		            podcast.episodes[i].status = EpisodeStatus.PLAYED;
		        }
		    }

		    cache_album_art(podcast);

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
		    info ("Opening/Creating Database: %s", db_location);
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
		 * Creates Leopod's config directory, establishes a database connection
		 * and initializes the database schema
		 */
		public bool setup_library () {
		    prepare_database ();

		    if (settings.get_string("library-location") == null) {
		        settings.set_string(
		            "library-location",
		            GLib.Environment.get_user_data_dir () + """/leopod"""
		        );
		    }
		    local_library_path = settings.get_string("library-location").replace (
		        "~",
		        GLib.Environment.get_home_dir ()
		    );

		    // If the local library path has been modified, update the setting
		    if (settings.get_string("library-location") != local_library_path) {
		        settings.set_string("library-location", local_library_path);
		    }

		    // Create the local library
		    GLib.DirUtils.create_with_parents (local_library_path, 0775);

		    // Create the leopod folder if it doesn't exist
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
		        INSERT OR UPDATE INTO Episode
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

		/*
		 * Downloads an episode to the filesystem
		 */
		public DownloadDetailBox download_episode (Episode episode) throws LeopodLibraryError {
		    string podcast_path = local_library_path + "/%s".printf (
 		        episode.parent.name.replace ("%27", "'").replace ("%", "_")
 		    );

 		    info (podcast_path);

 		    // Create a directory for downloads if it doesn't already exist.
 		    GLib.DirUtils.create_with_parents (podcast_path, 0775);
 		    DownloadDetailBox detail_box = null;


 		    // Locally cache the album art if necessary
 		    try {
 		        //Check if the remote file exists
 		        GLib.File remote_episode = GLib.File.new_for_uri (episode.uri);
 		        if (remote_episode.query_exists ()) {
 		            // If the episode file exists, set path for new file and create object for the local file
 		            string episode_path =
 		                podcast_path + "/" +
 		                remote_episode.get_basename ().replace ("%", "_");
 		            GLib.File local_episode = GLib.File.new_for_path (episode_path);

 		            if (!local_episode.query_exists ()) {
 		                //Create the DownloadDetailBox and GLib.Cancellable
 		                detail_box = new DownloadDetailBox (episode);
 		                FileProgressCallback callback = detail_box.download_delegate;
 		                GLib.Cancellable cancellable = new GLib.Cancellable ();

 		                detail_box.cancel_requested.connect ((episode) => {
 		                    cancellable.cancel ();
 		                    if (local_episode.query_exists ()) {
 		                        try {
 		                            local_episode.delete ();
 		                        } catch (Error e) {
 		                            error ("unable to delete file.");
 		                        }
 		                    }
 		                });

 		                detail_box.download_completed.connect ((episode) => {
 		                    // Mark the local path on the episode.
         		            episode.local_uri = "file://" + episode_path;
         		            episode.current_download_status = DownloadStatus.DOWNLOADED;
         		            episode.download_status_changed ();
         		            write_episode_to_database (episode);
 		                });
 		                // Download the episode
 		                remote_episode.copy_async (
 		                    local_episode,
 		                    FileCopyFlags.OVERWRITE,
 		                    GLib.Priority.DEFAULT,
 		                    cancellable,
 		                    callback
 		                );
 		            } else {
 		                episode.current_download_status = DownloadStatus.DOWNLOADED;
 		                episode.download_status_changed ();
 		                write_episode_to_database (episode);
 		                return null;
 		            }
 		        }
 		    } catch (Error e) {
 		        error ("unable to save a local copy of episode. %s", e.message);
 		    }
 		    return detail_box;
		}

		public void delete_episode (Episode episode) {
		    GLib.File local_file = GLib.File.new_for_uri (episode.local_uri);
		    if (local_file.query_exists ()) {
		        try {
		            local_file.delete ();
		        } catch (Error e) {
		            error ("unable to delete file.");
		        }
		    }
		    episode.current_download_status = DownloadStatus.NOT_DOWNLOADED;
		    episode.download_status_changed ();
		    write_episode_to_database (episode);
		}

		public void set_episode_playback_position (Episode episode) {
		    write_episode_to_database (episode);
		}

		public void mark_episode_as_played (Episode episode) {
		    episode.status = EpisodeStatus.PLAYED;
		    write_episode_to_database (episode);
		}
	}
}
