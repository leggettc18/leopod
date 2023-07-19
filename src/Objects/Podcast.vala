/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {
	public class Podcast {

	    public ObservableArrayList<Episode> episodes = null;

		public string remote_art_uri = "";
		public string local_art_uri = "";
		public string name = "";
		public string description = "";
		public string feed_uri = "";
		public License license;

		public MediaType content_type = MediaType.UNKNOWN;

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

		public Podcast () {
		    episodes = new ObservableArrayList<Episode> ();
            content_type = MediaType.UNKNOWN;
		}

		public Podcast.with_name (string name) {
            this ();
            this.name = name;
        }

		public Podcast.with_remote_art_uri (string uri) {
			remote_art_uri = uri;
		}

        /*
         * Add a new episode to the library
         */
        public void add_episode (Episode new_episode) {
            new_episode.podcast_uri = this.feed_uri;
            episodes.insert (0, new_episode);
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
