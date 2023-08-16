/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2023 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

class EpisodeWindow : Gtk.Window {
    public Episode episode { get; construct; }

    public EpisodeWindow (Episode episode) {
        Object (episode: episode);
    }

    construct {
        title = _(episode.parent.name + " - " + episode.title);
        titlebar = new Gtk.Grid () {
            visible = false
        };
        Gtk.HeaderBar header_bar = new Gtk.HeaderBar () {
            show_title_buttons = false
        };
        header_bar.add_css_class (Granite.STYLE_CLASS_FLAT);
        header_bar.pack_start (new Gtk.WindowControls (Gtk.PackType.START));
        header_bar.pack_end (new Gtk.WindowControls (Gtk.PackType.END));
        Gtk.Grid layout = new Gtk.Grid () {
            row_spacing = 12,
            column_spacing = 12,
            column_homogeneous = false,
        };
        layout.attach (header_bar, 0, 0, 2, 1);
        CoverArt coverart = new CoverArt (episode.parent, false) {
            margin_top = margin_start = 12,
            halign = Gtk.Align.START,
        };
        layout.attach (coverart, 0, 1);
        Gtk.Box titlebox = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            halign = Gtk.Align.START,
            hexpand = true,
            valign = Gtk.Align.CENTER,
            margin_top = margin_end = 12,
        };
        Gtk.Label podcast_name = new Gtk.Label (episode.parent.name) {
            css_classes = { Granite.STYLE_CLASS_H2_LABEL },
            halign = Gtk.Align.START,
        };
        Gtk.Label episode_name = new Gtk.Label (episode.title) {
            css_classes = { Granite.STYLE_CLASS_H3_LABEL },
            halign = Gtk.Align.START,
        };
        titlebox.append (podcast_name);
        titlebox.append (episode_name);
        layout.attach (titlebox, 1, 1);
        Gtk.Label desc_text = new Gtk.Label (Utils.html_to_markup (episode.description)) {
            wrap = true,
            use_markup = true,
            max_width_chars = 50,
            margin_bottom = margin_start = margin_end = 12,
        };
        layout.attach (desc_text, 0, 2, 2, 1);
        child = layout;
    }
}
}
