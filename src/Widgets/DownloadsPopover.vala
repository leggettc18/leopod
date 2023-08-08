/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public class DownloadsPopover : Gtk.Popover {
    private Gtk.Box box;
    private Gtk.FlowBox listbox;
    private Gtk.Label downloads_complete;
    public Gtk.Widget parent_widget { get; construct; }
    public DownloadManager download_manager { get; construct; }

    private Gtk.Widget create_download_detail_box (Object object) {
        return new DownloadDetailBox ((Download) object);
    }

    public DownloadsPopover (Gtk.Widget parent_widget, DownloadManager download_manager) {
        Object (parent_widget: parent_widget, download_manager: download_manager);
        download_manager.download_added.connect (hide_downloads_complete);
        download_manager.download_removed.connect (() => {
            if (download_manager.downloads.size == 0) {
                show_downloads_complete ();
            }
        });
        this.set_parent (parent_widget);
    }

    construct {
        add_css_class (Granite.STYLE_CLASS_BACKGROUND);
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

        listbox.bind_model (download_manager.downloads, create_download_detail_box);
        var scroll = new Gtk.ScrolledWindow ();
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

        set_child (scroll);
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
