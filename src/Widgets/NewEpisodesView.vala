/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {


public class NewEpisodesView : Gtk.Box {
    private Gtk.Box main_box;
    private EpisodeList list_box;
    public Library library { get; construct; }

    // Signals
    public signal void episode_download_requested (Episode episode);
    public signal void episode_delete_requested (Episode episode);
    public signal void episode_play_requested (Episode episode);

    private ObservableArrayList<Episode> episodes;


    public NewEpisodesView (Library library) {
        Object (library: library);
    }

    construct {
        Gtk.ScrolledWindow main_scrolled = new Gtk.ScrolledWindow () {
            margin_bottom = margin_start = margin_end = 20,
            margin_top = 0,
        };
        main_scrolled.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            halign = Gtk.Align.FILL,
            valign = Gtk.Align.START,
            vexpand = false,
            hexpand = true
        };
        main_scrolled.set_child (main_box);
        prepend (main_scrolled);
        episodes = get_new_episodes (library.podcasts);
        list_box = new EpisodeList (episodes, true, EpisodeListType.LIST, 8);
        list_box.episode_download_requested.connect ((episode) => {
            episode_download_requested (episode);
        });
        list_box.episode_delete_requested.connect ((episode) => {
            episode_delete_requested (episode);
        });
        list_box.episode_play_requested.connect ((episode) => {
            episode_play_requested (episode);
        });
        list_box.add_css_class (Granite.STYLE_CLASS_BACKGROUND);
        main_box.prepend (list_box);
    }

    /*
     * Gets a list of "new" episodes, sorted by release date.
     * An episode will be considered "new" if it is unplayed.
     * Since all but the most recent episode in a newly added
     * podcast is automatically marked as played, adding a new
     * podcast will not flood this list.
     */
    public ObservableArrayList<Episode> get_new_episodes (Gee.ArrayList<Podcast> podcasts) {
        info ("getting new episodes");
        var new_episodes = new ObservableArrayList<Episode> ();
        foreach (Podcast podcast in podcasts) {
            foreach (Episode episode in podcast.episodes) {
                if (episode.status == EpisodeStatus.UNPLAYED) {
                    new_episodes.add (episode);
                }
            }
        }
        new_episodes.sort (compare_release_dates);
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
    public int compare_release_dates (Episode first, Episode second) {
        return first.datetime_released.compare (second.datetime_released) * -1;
    }

    public void rebuild (Library library) {
        info ("rebuilding new episodes list");
        main_box.remove (list_box);
        episodes = get_new_episodes (library.podcasts);
        list_box.bind_model (episodes);
        main_box.append (list_box);
        main_box.show ();
    }
}

}
