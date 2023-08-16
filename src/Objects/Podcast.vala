/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {
    public errordomain PodcastConstructionError {
        ROW_PARSE_ERROR
    }

    public class Podcast : Object {

        public ObservableArrayList<Episode> episodes { get; private set; }

        public string remote_art_uri { get; construct set; }
        public string local_art_uri { get; construct set; }
        public string name { get; construct; }
        public string description { get; construct; }
        public string feed_uri { get; construct set; }
        public License license { get; construct; default = License.UNKNOWN; }

        public MediaType content_type {
            get; construct set; default = MediaType.UNKNOWN;
        }

        /*
         * Gets and sets the coverart, whether it's from a remote source
         * or locally cached.
         */
        public string coverart_uri {

            // If the album art is saved locally, return that path. Otherwise, return main album art URI.
            owned get {
                string[] uris = { local_art_uri, remote_art_uri };
                foreach (string uri in uris) {
                    if (uri != null && uri != "") {
                        GLib.File art = GLib.File.new_for_uri (uri);
                        if (art.query_exists ()) {
                            return uri;
                        }
                    }
                }
                // In rare instances where album art is not available at all, provide a "missing art" image to use
                // in library view
                return "resource:///com/github/leggettc18/leopod/missing.png";
            }

            // If the URI begins with "file://" set local uri, otherwise set the remote uri
            set {
                string[] split = value.split (":");
                string proto = split[0].ascii_down ();
                if (proto == "http" || proto == "https") {
                    remote_art_uri = value.replace ("%27", "'");
                } else {
                    local_art_uri = "file://" + value.replace ("%27", "'");
                }
            }
        }

        public Podcast (
            string name,
            string description,
            string feed_uri,
            string remote_art_uri,
            License license,
            MediaType content_type
        ) {
            Object (
                name: name,
                description: description,
                feed_uri: feed_uri,
                remote_art_uri: remote_art_uri,
                license: license,
                content_type: content_type
            );
        }

        public Podcast.from_sqlite_row (Sqlite.Statement stmt) throws PodcastConstructionError {
            string name = null;
            string feed_uri = null;
            string remote_art_uri = null;
            string local_art_uri = null;
            string description = null;
            MediaType content_type = MediaType.UNKNOWN;
            License license = License.UNKNOWN;

            for (int i = 0; i < stmt.column_count (); i++) {
                string column_name = stmt.column_name (i) ?? "<none>";
                string val = stmt.column_text (i) ?? "<none>";

                if (column_name == "name") {
                    name = val;
                } else if (column_name == "feed_uri") {
                    feed_uri = val;
                } else if (column_name == "album_art_url") {
                    remote_art_uri = val;
                } else if (column_name == "album_art_local_uri") {
                    local_art_uri = val;
                } else if (column_name == "description") {
                    description = val;
                } else if (column_name == "content_type") {
                    if (val == "audio") {
                        content_type = MediaType.AUDIO;
                    } else if (val == "video") {
                        content_type = MediaType.VIDEO;
                    } else {
                        content_type = MediaType.UNKNOWN;
                    }
                } else if (column_name == "license") {
                    if (val == "cc") {
                        license = License.CC;
                    } else if (val == "public") {
                        license = License.PUBLIC;
                    } else if (val == "reserved") {
                        license = License.RESERVED;
                    } else {
                        license = License.UNKNOWN;
                    }
                }
            }

            if (description == null || name == null) {
                throw new PodcastConstructionError.ROW_PARSE_ERROR ("Required database column is not present");
            }

            Object (
                name: name,
                feed_uri: feed_uri,
                remote_art_uri: remote_art_uri,
                local_art_uri: local_art_uri,
                description: description,
                content_type: content_type,
                license: license
            );
        }

        public Podcast.with_name (string name) {
            Object (name: name);
        }

        construct {
            episodes = new ObservableArrayList<Episode> ();
        }

        /*
         * Add a new episode to the library
         */
        public void add_episode (Episode new_episode) {
            new_episode.podcast_uri = this.feed_uri;
            episodes.insert (0, new_episode);
        }

        public void add_episodes (ListModel episodes) {
            if (episodes.get_item_type () == typeof (Episode)) {
                for (int i = 0; i < episodes.get_n_items (); i++) {
                    Episode episode = (Episode) episodes.get_item (i);
                    episode.podcast_uri = this.feed_uri;
                    this.episodes.add (episode);
                }
            }
        }

        public void cache_album_art (string local_library_path) throws Error {
            string podcast_path = local_library_path + "/%s".printf (
                name.replace ("%27", "'").replace ("%", "_")
            );

            // Create a directory for downloads and artwork caching
            GLib.DirUtils.create_with_parents (podcast_path, 0775);

            // Locally cache the album art if necessary
            // Don't user the coverart_path getter, use the remote_uri
            File remote_art = File.new_for_uri (remote_art_uri);
            if (remote_art.query_exists ()) {
                // If the remote art exists, set path for new file and create object for the local file
                string art_path = podcast_path + "/" + remote_art.get_basename ().replace ("%", "_");
                File local_art = File.new_for_path (art_path);

                if (!local_art.query_exists ()) {
                    // Cache the art
                    remote_art.copy (local_art, FileCopyFlags.NONE);
                }
                // Mark the local path on the podcast
                local_art_uri = "file://" + art_path;
            }
        }
    }

    /*
     * The possible types of media that a podcast might contain, generally either audio or video.
     */
    public enum MediaType {
        AUDIO, VIDEO, UNKNOWN;
    }

    /*
     * The legal license that a podcast is listed as (if known)
     */
    public enum License {
        UNKNOWN, RESERVED, CC, PUBLIC;
    }
}
