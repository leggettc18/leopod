/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2023 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public enum EpisodeListType {
    GRID, LIST
}

public class EpisodeList : Gtk.Widget {
    public ObservableArrayList<Episode> episodes { get; construct; }
    public bool show_coverart { get; construct; }
    public EpisodeListType list_type { get; construct; }
    public int desc_lines { get; construct; }

    private Gtk.FlowBox list_box;

    // Signals
    public signal void episode_download_requested (Episode episode);
    public signal void episode_delete_requested (Episode episode);
    public signal void episode_play_requested (Episode episode);

    public EpisodeList (
        ObservableArrayList<Episode> episodes,
        bool show_coverart,
        EpisodeListType list_type,
        int desc_lines
    ) {
        Object (episodes: episodes, show_coverart: show_coverart, list_type: list_type, desc_lines: desc_lines);
    }

    construct {
        layout_manager = new Gtk.BoxLayout (Gtk.Orientation.VERTICAL);
        list_box = new Gtk.FlowBox () {
            homogeneous = true,
        };
        if (list_type == EpisodeListType.LIST) {
            list_box.max_children_per_line = 1;
        }
        list_box.bind_model (episodes, create_list_box_item);
        list_box.set_parent (this);
    }

    private Gtk.Widget create_list_box_item (Object object) {
        Episode episode = (Episode) object;
        var list_item = new EpisodeListItem ((Episode) episode, show_coverart) {
            desc_lines = desc_lines,
        };
        list_item.download_clicked.connect ((episode) => {
                episode_download_requested (episode);
                });
        list_item.delete_requested.connect ((episode) => {
                episode_delete_requested (episode);
                });
        list_item.play_requested.connect ((e) => {
                episode_play_requested (e);
                });
        return list_item;
    }

    public void bind_model (ListModel episodes) {
        list_box.bind_model (episodes, create_list_box_item);
    }

}

}
