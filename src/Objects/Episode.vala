/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leapod {
	public class Episode : GLib.Object {

        public string guid = null;
        public string link = "";
		public string title = "";
		public string description = "";
		public string uri = "";
		public string podcast_uri = "";
		public string date_released;
		
		public Podcast parent;
		public DateTime datetime_released;

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
}
