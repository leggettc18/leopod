/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leapod {
	public class Podcast {

		public string remote_art_uri = "";

		public Podcast () {

		}

		public Podcast.with_remote_art_uri (string uri) {
			remote_art_uri = uri;
		}
	}
}
