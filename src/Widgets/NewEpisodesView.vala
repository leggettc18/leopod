/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public class NewEpisodesView : Gtk.ScrolledWindow {
    public Gtk.Box main_box;
    public Gtk.ListBox list_box;

    // Signals
    public signal void episode_download_requested (Episode episode);
    public signal void episode_delete_requested (Episode episode);
    public signal void episode_play_requested (Episode episode);

    public NewEpisodesView (Library library) {
        set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin = 20,
            halign = Gtk.Align.FILL,
            valign = Gtk.Align.START,
            vexpand = false
        };
        add (main_box);
        list_box = new Gtk.ListBox ();
        Gee.ArrayList<Episode> episodes = get_new_episodes(library.podcasts);
        foreach (Episode episode in episodes) {
            var coverart = new CoverArt.with_podcast (episode.parent);
            var list_item = new EpisodeListItem (episode) {
                desc_lines = 8
            };
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
            box.add (coverart);
            box.add (list_item);
            list_box.add (box);
        }
        main_box.add (list_box);
    }

    /*
	 * Gets a list of "new" episodes, sorted by release date.
	 * An episode will be considered "new" if it is unplayed.
	 * Since all but the most recent episode in a newly added
	 * podcast is automatically marked as played, adding a new
	 * podcast will not flood this list.
	 */
	public Gee.ArrayList<Episode> get_new_episodes (Gee.ArrayList<Podcast> podcasts) {
		var new_episodes = new Gee.ArrayList<Episode> ();
		foreach (Podcast podcast in podcasts) {
			foreach (Episode episode in podcast.episodes) {
				if (episode.status == EpisodeStatus.UNPLAYED) {
				    new_episodes.add (episode);
				}
			}
		}
		new_episodes.sort (CompareReleaseDates);
		return new_episodes;
	}

	/*
	 * Compares two DateTimes and returns:
	 * Positive Integer: first is less than second
	 * 0: first is equal to second
	 * Negative Integer: first is greater than second
	 * This is specifically returning the reverse order so the
	 * larger datetimes come first, as these are the more recent episodes.
	 */
	public int CompareReleaseDates (Episode first, Episode second) {
	    return first.datetime_released.compare (second.datetime_released) * -1;
	}
}

}
