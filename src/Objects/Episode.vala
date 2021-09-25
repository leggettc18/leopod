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

		public Episode () {

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
        DOWNLOADED, NOT_DOWNLOADED;
    }
}
