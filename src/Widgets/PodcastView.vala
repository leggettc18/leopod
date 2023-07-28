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
    public Gtk.FlowBox episodes_list;
    private Gtk.Box right_box;
    private Granite.Placeholder placeholder;

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

    private int EpisodeListItemSortFunc(Gtk.FlowBoxChild row1, Gtk.FlowBoxChild row2) {
        EpisodeListItem item1 = (EpisodeListItem) row1.get_child();
        EpisodeListItem item2 = (EpisodeListItem) row2.get_child();

        return
        item1.episode.datetime_released.compare(item2.episode.datetime_released)
        * -1;
    }

    public PodcastView (Podcast podcast, uint transition_duration = 500) {
        Object(
            podcast: podcast,
            transition_duration: transition_duration
        );
    }

    construct {
        info ("Creating the podcast episodes view");
        // Create the view that will display all the episodes of a given podcast.
        orientation = Gtk.Orientation.HORIZONTAL;
        spacing = 5;
        Gtk.Box left_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5) {
            vexpand = false,
            margin_start = margin_end = margin_top = margin_bottom = 20
        };
        right_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10) {
            vexpand = true,
            margin_start = 20,
        };
        placeholder = new Granite.Placeholder ("Loading Episodes...");
        right_box.append(placeholder);
        //right_scrolled.get_style_context ().add_class ("episode-list-box");
        //prepend (left_box);
        CoverArt coverart = new CoverArt (podcast);
        left_box.prepend(coverart);
        left_box.append(new Gtk.Label (podcast.description) {
            wrap = true,
            width_chars = 25,
            max_width_chars = 30,
            single_line_mode = true,
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
        Gtk.Paned paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
            start_child = left_box,
            shrink_start_child = true,
            resize_start_child = false,
            end_child = right_box,
            shrink_end_child = false,
            resize_end_child = true,
        };
        append(paned);
            populate_episode_list.begin((obj, res) => {
                populate_episode_list.end(res);
            });
    }

    private async void populate_episode_list () {
        SourceFunc callback = populate_episode_list.callback;
        info ("transition_duration: %u", transition_duration);
        
        Timeout.add(transition_duration, () => {
            ThreadFunc<void> run = () => {
                Gtk.ScrolledWindow right_scrolled = new Gtk.ScrolledWindow () {
                    vexpand = true,
                    hexpand = true,
                };
                episodes_list = new Gtk.FlowBox () {
                    vexpand = true,
                    margin_end = 10,
                    selection_mode = Gtk.SelectionMode.NONE,
                    homogeneous = true,
                };
                episodes_list.add_css_class(Granite.STYLE_CLASS_RICH_LIST);
                episodes_list.set_sort_func(EpisodeListItemSortFunc);
                right_scrolled.set_child (episodes_list);
                episodes_list.bind_model(podcast.episodes, CreateEpisodeListItem);
                right_box.remove(placeholder);
                right_box.append(right_scrolled);
                Idle.add((owned) callback);
            };
            new Thread<void> ("populate_episode_list", (owned) run);
            return false;
            });
        yield;
    }
}

}
