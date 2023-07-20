/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public class PodcastView : Gtk.Box {
    // Signals
    public signal void episode_download_requested (Episode episode);
    public signal void episode_delete_requested (Episode episode);
    public signal void episode_play_requested (Episode episode);
    public signal void podcast_delete_requested (Podcast podcast);

    // Widgets
    public Gtk.ListBox episodes_list;

    // Data
    public ObservableArrayList<EpisodeListItem> episodes;

    private Gtk.Widget CreateEpisodeListItem(GLib.Object object) {
        Episode episode = (Episode) object;
        var episode_list_item = new EpisodeListItem (episode);
        episode_list_item.download_clicked.connect ((episode) => {
                episode_download_requested (episode);
                });
        episode_list_item.delete_requested.connect ((episode) => {
                episode_delete_requested (episode);
                });
        episode_list_item.play_requested.connect ((e) => {
                episode_play_requested (e);
                });
        return episode_list_item;
    }

    private int EpisodeListItemSortFunc(Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
        EpisodeListItem item1 = (EpisodeListItem) row1.get_child();
        EpisodeListItem item2 = (EpisodeListItem) row2.get_child();

        return
        item1.episode.datetime_released.compare(item2.episode.datetime_released)
        * -1;
    }

    public PodcastView (Podcast podcast) {
        info ("Creating the podcast episodes view");
        // Create the view that will display all the episodes of a given podcast.
        orientation = Gtk.Orientation.HORIZONTAL;
        spacing = 5;
        Gtk.Box left_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5) {
            vexpand = false,
            margin_start = margin_end = margin_top = margin_bottom = 20
        };
        Gtk.ScrolledWindow right_scrolled = new Gtk.ScrolledWindow () {
            vexpand = true,
            hexpand = true,
        };
        Gtk.Box right_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10) {
            vexpand = true,
            margin_start = 20,
        };
        //right_scrolled.get_style_context ().add_class ("episode-list-box");
        prepend (left_box);
        episodes_list = new Gtk.ListBox () {
            vexpand = true,
            show_separators = true,
            margin_end = 10,
        };
        episodes_list.get_style_context().add_class("episodes-list");
        episodes_list.set_sort_func(EpisodeListItemSortFunc);
        right_scrolled.set_child (episodes_list);
        right_box.prepend (right_scrolled);
        append(right_box);
        CoverArt coverart = new CoverArt.with_podcast (podcast);
        left_box.prepend(coverart);
        left_box.append(new Gtk.Label (podcast.description) {
            wrap = true,
            max_width_chars = 25
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
        podcast_delete_button.get_style_context ().add_class ("danger");
        left_box.append(podcast_delete_box);
        podcast_delete_button.clicked.connect(() => {
            podcast_delete_requested (podcast);
        });
        episodes_list.bind_model(podcast.episodes, CreateEpisodeListItem);
        //var children = episodes_list.observe_children().foreach ((child) => {
         //   child.get_style_context ().add_class ("episode-list");
        //});
    }
}

}
