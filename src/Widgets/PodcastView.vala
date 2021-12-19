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
    public Gee.ArrayList<EpisodeListItem> episodes;

    public PodcastView (Podcast podcast) {
        info ("Creating the podcast episodes view");
        // Create the view that will display all the episodes of a given podcast.
        orientation = Gtk.Orientation.HORIZONTAL;
        spacing = 5;
        halign = Gtk.Align.FILL;
        valign = Gtk.Align.FILL;
        Gtk.Box left_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5) {
            halign = Gtk.Align.FILL,
            valign = Gtk.Align.START,
            vexpand = false,
            margin = 20
        };
        Gtk.Box right_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10) {
            halign = Gtk.Align.FILL,
            margin = 10,
        };
        pack_start (left_box);
        add (right_box);
        CoverArt coverart = new CoverArt.with_podcast (podcast);
        left_box.add (coverart);
        left_box.add (new Gtk.Label (podcast.description) {
            wrap = true,
            max_width_chars = 25
        });
        Gtk.Button podcast_delete_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.BUTTON) {
            tooltip_text = _("Unsubscribe from Podcast"),
            relief = Gtk.ReliefStyle.NORMAL,
            label = "Unsubscribe",
            always_show_image = true,
        };
        Gtk.Box podcast_delete_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5) {
            halign = Gtk.Align.CENTER,
            expand = false
        };
        podcast_delete_box.add (podcast_delete_button);
        podcast_delete_button.get_style_context ().add_class ("danger");
        left_box.add (podcast_delete_box);
        podcast_delete_button.clicked.connect(() => {
            podcast_delete_requested (podcast);
        });
        episodes_list = new Gtk.ListBox ();
        right_box.add (episodes_list);
        foreach (Episode episode in podcast.episodes) {
            var episode_list_item = new EpisodeListItem (episode);
            episodes_list.prepend (episode_list_item);
            episode_list_item.download_clicked.connect ((episode) => {
                episode_download_requested (episode);
            });
            episode_list_item.delete_requested.connect ((episode) => {
                episode_delete_requested (episode);
            });
            episode_list_item.play_requested.connect ((e) => {
                episode_play_requested (e);
            });
        }
        episodes_list.get_children ().foreach ((child) => {
            child.get_style_context ().add_class ("episode-list");
        });
    }
}

}
