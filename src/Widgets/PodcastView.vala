/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public class PodcastView : Gtk.Box {
    public Podcast podcast { get; construct; }
    public uint transition_duration { get; construct; }

    // Signals
    public signal void episode_download_requested (Episode episode);
    public signal void episode_delete_requested (Episode episode);
    public signal void episode_play_requested (Episode episode);
    public signal void podcast_delete_requested (Podcast podcast);

    // Widgets
    public EpisodeList episodes_list;
    private Granite.Placeholder placeholder;
    private Gtk.Paned paned;
    private Gtk.ScrolledWindow right_scrolled;

    // Data
    public ObservableArrayList<EpisodeListItem> episodes;

    public PodcastView (Podcast podcast, uint transition_duration = 500) {
        Object (
            podcast: podcast,
            transition_duration: transition_duration
        );
    }

    construct {
        info ("Creating the podcast episodes view for %s", podcast.name);
        // Create the view that will display all the episodes of a given podcast.
        orientation = Gtk.Orientation.HORIZONTAL;
        Gtk.Box left_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5) {
            vexpand = false,
            hexpand = false,
            margin_start = margin_end = margin_top = margin_bottom = 20
        };
        placeholder = new Granite.Placeholder ("Loading Episodes…");
        right_scrolled = new Gtk.ScrolledWindow () {
            vexpand = true,
            hexpand = true,
            child = placeholder,
        };
        //right_scrolled.get_style_context ().add_class ("episode-list-box");
        //prepend (left_box);
        CoverArt coverart = new CoverArt (podcast);
        left_box.prepend (coverart);
        string description = Utils.html_to_markup (podcast.description);
        left_box.append (new Gtk.Label (description) {
            wrap = true,
            width_chars = 25,
            max_width_chars = 30,
            single_line_mode = true,
            hexpand = false,
            use_markup = true,
        });
        Gtk.Button podcast_delete_button = new Gtk.Button.with_label
        (_("Unsubscribe")) {
            tooltip_text = _("Unsubscribe from Podcast"),
        };
        Gtk.Box podcast_delete_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5) {
            halign = Gtk.Align.CENTER,
            hexpand = false
        };
        podcast_delete_box.append (podcast_delete_button);
        podcast_delete_button.add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);
        left_box.append (podcast_delete_box);
        podcast_delete_button.clicked.connect (() => {
            podcast_delete_requested (podcast);
        });
        paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
            start_child = left_box,
            shrink_start_child = false,
            resize_start_child = false,
            end_child = right_scrolled,
            shrink_end_child = false,
            resize_end_child = true,
        };
        append (paned);
        Timeout.add (transition_duration + 100, () => {
            populate_episode_list.begin ((obj, res) => {
                populate_episode_list.end (res);
            });
            return false;
        });
    }

    public void unbind_model () {
        episodes_list.unbind_model ();
    }

    private async void populate_episode_list () {
        SourceFunc callback = populate_episode_list.callback;
        podcast.episodes.sort (Episode.episode_sort_func);
        episodes_list = new EpisodeList (podcast.episodes, false, EpisodeListType.GRID, 3) {
            margin_end = 6,
        };
        episodes_list.episode_download_requested.connect ((episode) => {
            episode_download_requested (episode);
        });
        episodes_list.episode_delete_requested.connect ((episode) => {
            episode_delete_requested (episode);
        });
        episodes_list.episode_play_requested.connect ((episode) => {
            episode_play_requested (episode);
        });
        episodes_list.add_css_class (Granite.STYLE_CLASS_RICH_LIST);
        right_scrolled.child = episodes_list;
        Idle.add ((owned) callback);
        yield;
    }
}

}
