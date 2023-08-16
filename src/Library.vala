/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

    public errordomain LeopodLibraryError {
        ADD_ERROR, IMPORT_ERROR, MISSING_URI;
    }

    public class Library : Object {
        public ObservableArrayList<Podcast> podcasts { get; set; }
        public Application app { get; construct; }

        private Sqlite.Database db; // the Database

        private string db_location = null;
        private string leopod_config_dir = null;
        private string db_directory = null;
        private string local_library_path;

        public signal void library_loaded ();

        public Library (Application app) {
            Object (app: app);
        }

        construct {
            leopod_config_dir = GLib.Environment.get_user_config_dir () + "/leopod";
            this.db_directory = leopod_config_dir + "/database";
            this.db_location = this.db_directory + "/leopod.db";
            info (db_location);

            podcasts = new ObservableArrayList<Podcast> ();

            // Set the local library directory and replace ~ with absolute path
            local_library_path = GLib.Environment.get_user_data_dir () + "/leopod";
            local_library_path = local_library_path.replace (
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

        public Gee.ArrayList<Episode> check_for_updates () {
            Gee.ArrayList<Episode> new_episodes = new Gee.ArrayList<Episode> ();

            FeedParser parser = new FeedParser ();

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
                    new_episodes.add (podcast.episodes[added - 1]);
                    write_episode_to_database (podcast.episodes[added - 1]);
                    added--;
                }

                if (added == -1) {
                    critical ("Unable to update podcast due to missing feed url");
                }
            }

            return new_episodes;
        }

        /*
         * Refills the library from the database
         */
        public async void refill_library () {
            Idle.add (refill_library.callback);
            yield;
            podcasts.clear ();
            prepare_database ();

            Sqlite.Statement stmt;

            string prepared_query = "SELECT * FROM Podcast ORDER BY name;";
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
            info ("loading podcasts from db");
            foreach (Podcast podcast in podcasts) {
                prepared_query = string.join (" ",
                    "SELECT e.*, p.name as parent_podcast_name",
                    "FROM Episode e",
                    "LEFT JOIN Podcast p on p.feed_uri = e.podcast_uri",
                    "WHERE podcast_uri = '%s'",
                    "ORDER BY e.released ASC;"
                ).printf (podcast.feed_uri);
                ec = db.prepare_v2 (prepared_query, prepared_query.length, out stmt);
                if (ec != Sqlite.OK) {
                    warning ("%d: %s", db.errcode (), db.errmsg ());
                    return;
                }
                while (stmt.step () == Sqlite.ROW) {
                    Episode episode = episode_from_row (stmt);
                    episode.parent = podcast;

                    podcast.add_episode (episode);
                }
                stmt.reset ();
            }
            library_loaded ();
        }

        public Podcast podcast_from_row (Sqlite.Statement stmt) {
            Podcast podcast = null;
            try {
                podcast = new Podcast.from_sqlite_row (stmt);
            } catch (PodcastConstructionError e) {
                critical (e.message);
            }
            return podcast;
        }

        public Episode episode_from_row (Sqlite.Statement stmt) {
            Episode episode = null;
            try {
                episode = new Episode.from_sqlite_row (stmt);
            } catch (EpisodeConstructionError.ROW_PARSING_ERROR e) {
                critical (e.message);
            }
            return episode;
        }

        /*
         * Downloads and Caches a podcast's album art if it doesn't
         * already exist.
         */
         public void cache_album_art (Podcast podcast) {
            try {
                podcast.cache_album_art (local_library_path);
            } catch (Error e) {
                error ("unable to save a local copy of album art. %s", e.message);
            }
         }

        private int sort_podcasts (Podcast a, Podcast b) {
            return a.name.ascii_casecmp (b.name);
        }

        /*
         * Adds a podcast to the database and the active podcast list
         */
        public async bool add_podcast (Podcast? podcast) throws LeopodLibraryError {
            if (podcast == null) {
                warning ("Podcast is null");
                return false;
            }
            info ("Podcast %s is being added to the library", podcast.name);

            // Set all but the most recent episode as played
            if (podcast.episodes.size > 0) {
                for (int i = 1; i < podcast.episodes.size; i++) {
                    podcast.episodes[i].status = EpisodeStatus.PLAYED;
                }
            }
            info ("marked all episodes but the latest one as played");

            cache_album_art (podcast);

            // Add it to the local arraylist
            podcasts.add (podcast);
            podcasts.sort (sort_podcasts);
            info ("added podcast to the in-memory list");
            yield save_podcast (podcast);
            return true;
        }

        private async void save_podcast (Podcast podcast) throws LeopodLibraryError {
            SourceFunc callback = save_podcast.callback;
            ThreadFunc<void> run = () => {

                if (write_podcast_to_database (podcast)) {
                    info ("wrote podcast to the database");

                    // Fill in the podcast's episodes
                    foreach (Episode episode in podcast.episodes) {
                        episode.podcast_uri = podcast.feed_uri;
                        write_episode_to_database (episode);
                    }
                    info ("wrote episodes to database");
                } else {
                    warning ("failed adding podcast '%s'.", podcast.name);
                }
                Idle.add ((owned) callback);
            };
            new Thread<void> ("save_podcast", (owned) run);
            yield;
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
                critical (
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

            local_library_path = GLib.Environment.get_user_data_dir () + "/leopod";
            local_library_path = local_library_path.replace (
                "~",
                GLib.Environment.get_home_dir ()
            );

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

            string query = string.join ("",
                "BEGIN TRANSACTION;\n",
                "CREATE TABLE Podcast (",
                "    name                TEXT                    NOT NULL,",
                "    feed_uri            TEXT    PRIMARY_KEY     NOT NULL,",
                "    album_art_url       TEXT,",
                "    album_art_local_uri TEXT,",
                "    description         TEXT                    NOT NULL,",
                "    content_type        TEXT,",
                "    license             TEXT",
                ");\n",
                "CREATE INDEX podcast_name ON Podcast (name);\n",
                "CREATE TABLE Episode (",
                "    title               TEXT                    NOT NULL,",
                "    podcast_uri         TEXT                    NOT NULL,",
                "    uri                 TEXT                    NOT NULL,",
                "    local_uri           TEXT,",
                "    released            INT,",
                "    description         TEXT,",
                "    latest_position     TEXT,",
                "    download_status     TEXT,",
                "    play_status         TEXT,",
                "    guid                TEXT,",
                "    link                TEXT",
                ");\n",
                "CREATE UNIQUE INDEX episode_guid ON Episode (guid, link, podcast_uri);\n",
                "CREATE INDEX episode_title ON Episode (title);\n",
                "CREATE INDEX episode_released ON Episode (released);\n",
                "PRAGMA user_version = 1;\n",
                "END TRANSACTION;"
            );

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

            string query =
                "INSERT OR REPLACE INTO Episode " +
                "(title, podcast_uri, uri, local_uri, released, description, " +
                "latest_position, download_status, play_status, guid, link) " +
                "VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11);";

            Sqlite.Statement stmt;
            int ec = db.prepare_v2 (query, query.length, out stmt);

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
            if (episode.local_uri == null) {
                stmt.bind_null (4);
            } else {
                stmt.bind_text (4, episode.local_uri);
            }
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
        public void download_episode (Episode episode) throws LeopodLibraryError {
            try {
                app.download_manager.add_episode_download (episode);
            } catch (DownloadError e) {
                error (e.message);
            }
            episode.download_status_changed.connect (() => {
                if (episode.current_download_status == DownloadStatus.DOWNLOADED) {
                    write_episode_to_database (episode);
                }
            });
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

        public async void delete_podcast (Podcast podcast) {
            SourceFunc callback = delete_podcast.callback;

            podcasts.remove (podcast);

            ThreadFunc<void> run = () => {
            // Delete all the episodes
            foreach (Episode episode in podcast.episodes) {
                // Delete from filesystem
                GLib.File local_file = GLib.File.new_for_uri (episode.local_uri);
                if (local_file.query_exists ()) {
                    try {
                        local_file.delete ();
                    } catch (Error e) {
                        error ("unable to delete file.");
                    }
                }
                // Delete from database
                string query =
                    "DELETE FROM Episode " +
                    "WHERE guid = ?1;";
                Sqlite.Statement stmt;
                int ec = db.prepare_v2 (query, query.length, out stmt);

                if (ec != Sqlite.OK) {
                    warning (
                        "unable to prepare delete episode statment. %d: %s",
                        db.errcode (),
                        db.errmsg ()
                    );
                }

                stmt.bind_text (1, episode.guid);

                ec = stmt.step ();

                if (ec != Sqlite.DONE) {
                    warning (
                        "unable to delete episode from db. %d: %s",
                        db.errcode (),
                        db.errmsg ()
                    );
                }
            }
            // Delete the podcast from the database.
            string query = """
                DELETE FROM Podcast
                WHERE feed_uri = ?1;
            """;

            Sqlite.Statement stmt;
            int ec = db.prepare_v2 (query, query.length, out stmt);
            if (ec != Sqlite.OK) {
                warning (
                    "unable to prepare delete podcast statement. %d: %s",
                    db.errcode (),
                    db.errmsg ()
                );
            }

            stmt.bind_text (1, podcast.feed_uri);
            ec = stmt.step ();
            if (ec != Sqlite.DONE) {
                warning (
                    "unable to delete podcast from db. %d: %s",
                    db.errcode (),
                    db.errmsg ()
                );
            }
            Idle.add ((owned) callback);
            };
            new Thread<void> ("delete_podcast", (owned) run);
            yield;
        }

        private inline void ret_to_ex (int errc) throws FileError {
            if (errc < 0) {
                throw new FileError.FAILED ("failed");
            }
        }

        public void export_to_opml (string path) {
            DateTime now = new DateTime.now (new TimeZone.local ());
            try {
                Xml.TextWriter writer = new Xml.TextWriter.filename (path, false);
                if (writer == null) {
                    error ("Error: Xml.TextWriter.filename () == null");
                }
                ret_to_ex (writer.start_document ("1.0", "utf-8"));
                ret_to_ex (writer.start_element ("opml"));
                ret_to_ex (writer.write_attribute ("version", "1.0"));
                ret_to_ex (writer.start_element ("head"));
                ret_to_ex (writer.start_element ("title"));
                ret_to_ex (writer.write_string ("Leopod Subscriptions Export"));
                ret_to_ex (writer.end_element ());
                ret_to_ex (writer.start_element ("dateCreated"));
                ret_to_ex (writer.write_string (now.to_string ()));
                ret_to_ex (writer.end_element ());
                ret_to_ex (writer.start_element ("dateModified"));
                ret_to_ex (writer.write_string (now.to_string ()));
                ret_to_ex (writer.end_element ());
                ret_to_ex (writer.end_element ());
                ret_to_ex (writer.start_element ("body"));
                foreach (Podcast podcast in podcasts) {
                    ret_to_ex (writer.start_element ("outline"));
                    ret_to_ex (writer.write_attribute ("text", podcast.name.replace ("\"", "'").replace ("&", "and")));
                    ret_to_ex (writer.write_attribute ("type", "rss"));
                    ret_to_ex (writer.write_attribute ("xmlUrl", podcast.feed_uri));
                    ret_to_ex (writer.end_element ());
                }
                ret_to_ex (writer.end_element ());
                ret_to_ex (writer.end_element ());
                ret_to_ex (writer.flush ());
            } catch (Error e) {
                error (e.message);
            }
        }
    }
}
