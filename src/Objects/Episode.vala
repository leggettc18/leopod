/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {
	public class Episode : GLib.Object {

        public string guid = null;
        public string link = "";
		public string title = "";
		public string description = "";
		public string uri = "";
		public string local_uri = "";
		public string podcast_uri = "";
		public int last_played_position;
		public string date_released;

		public Podcast parent;
		public DateTime datetime_released;

		public EpisodeStatus status;
		public DownloadStatus current_download_status;

		public signal void download_status_changed ();

		/*
		 * Gets the playback uri based on whether the file is local or remote
		 * Sets the playback uri based on whether it's local or remote
		 */
		public string playback_uri {
			get {
				GLib.File local;

				if (local_uri != null) {
					if (local_uri.contains ("file://")) {
						local = GLib.File.new_for_uri (local_uri);
					} else {
						local = GLib.File.new_for_uri ("file://" + local_uri);
					}

					if (local.query_exists ()) {
						if (local_uri.contains ("file://")) {
							return local_uri;
						} else {
							local_uri = "file://" + local_uri;
							return local_uri;
						}
					} else {
						return uri;
					}
				} else {
					return uri;
				}
			}

			set {
				string[] split = value.split (":");
				if (split[0] == "http" || split[0] == "HTTP") {
					uri = value;
				} else {
					if (!value.contains ("file://")) {
						local_uri = """file://""" + value;
					} else {
						local_uri = value;
					}
				}
			}
		}

		public Episode () {
		    parent = null;
		    local_uri = null;
		    status = EpisodeStatus.UNPLAYED;
            current_download_status = DownloadStatus.NOT_DOWNLOADED;
            last_played_position = 0;
		}

		/*
        * Sets the local datetime based on the standardized "pubdate" as listed
        * in the feed.
        */
        public void set_datetime_from_pubdate () {
            if (date_released != null) {
                GLib.Time tm = GLib.Time ();
                tm.strptime (date_released, "%a, %d %b %Y %H:%M:%S %Z");
                datetime_released = new DateTime.local (
                    1900 + tm.year,
                    1 + tm.month,
                    tm.day,
                    tm.hour,
                    tm.minute,
                    tm.second
                );
            }
        }
	}

	/*
     * Possible episode playback statuses, either played or unplayed. In Vocal 2.0 it would be
     * beneficial to have an additional value to determine if the episode is finished
     * or simply started.
     */
    public enum EpisodeStatus {
        PLAYED, UNPLAYED;
    }

    /*
     * Possible episode download statuses, either downloaded or not downloaded.
     */
    public enum DownloadStatus {
        DOWNLOADED,
        NOT_DOWNLOADED;
    }
}
