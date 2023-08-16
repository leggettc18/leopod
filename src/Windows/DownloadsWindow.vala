/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2023 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public class DownloadsWindow : Gtk.Window {
    private Gtk.Box box;
    private Gtk.FlowBox listbox;
    private Gtk.Label downloads_complete;
    public Gtk.Widget parent_widget { get; construct; }
    public DownloadManager download_manager { get; construct; }

    private Gtk.Widget create_download_detail_box (Object object) {
        return new DownloadDetailBox ((Download) object);
    }

    public DownloadsWindow (DownloadManager download_manager) {
        Object (download_manager: download_manager);
        download_manager.download_added.connect (hide_downloads_complete);
        download_manager.download_removed.connect (() => {
            if (download_manager.downloads.size == 0) {
                show_downloads_complete ();
            }
        });
    }

    construct {
        title = _("Downloads");
        titlebar = new Gtk.Grid () {
            visible = false,
        };
        Gtk.HeaderBar header_bar = new Gtk.HeaderBar () {
            show_title_buttons = false,
        };
        header_bar.add_css_class (Granite.STYLE_CLASS_FLAT);
        header_bar.pack_start (new Gtk.WindowControls (Gtk.PackType.START));
        header_bar.pack_end (new Gtk.WindowControls (Gtk.PackType.END));
        add_css_class (Granite.STYLE_CLASS_BACKGROUND);
        Gtk.Grid layout = new Gtk.Grid () {
            row_spacing = column_spacing = 12,
            column_homogeneous = false,
        };
        layout.attach (header_bar, 0, 0);
        this.box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = Gtk.Align.CENTER
        };
        box.add_css_class (Granite.STYLE_CLASS_BACKGROUND);
        this.listbox = new Gtk.FlowBox () {
            selection_mode = Gtk.SelectionMode.NONE,
            max_children_per_line = 1,
            orientation = Gtk.Orientation.HORIZONTAL,
            margin_start = margin_end = 12,
        };
        listbox.add_css_class (Granite.STYLE_CLASS_BACKGROUND);
        this.width_request = 425;
        this.height_request = 600;

        listbox.bind_model (download_manager.downloads, create_download_detail_box);
        var scroll = new Gtk.ScrolledWindow () {
            hexpand = true,
        };
        scroll.add_css_class (Granite.STYLE_CLASS_BACKGROUND);
        scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scroll.min_content_height = 200;
        scroll.set_child (box);
        box.append (listbox);

        downloads_complete = new Gtk.Label (_("No Active Downloads"));
        downloads_complete.get_style_context ().add_class ("h3");
        downloads_complete.sensitive = false;
        //downloads_complete.margin = 12;
        box.prepend (downloads_complete);
        layout.attach (scroll, 0, 1);
        set_child (layout);
    }

    private void hide_downloads_complete () {
        //downloads_complete.no_show_all = true;
        downloads_complete.set_visible (false);
    }

    private void show_downloads_complete () {
        //downloads_complete.no_show_all = false;
        downloads_complete.set_visible (true);
    }
}

}
