/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public class DownloadsPopover : Gtk.Popover {
    private Gtk.ListBox listbox;
    private Gtk.Label downloads_complete;
    public Gee.ArrayList<DownloadDetailBox> downloads;

    public DownloadsPopover (Gtk.Widget parent) {
        this.set_parent(parent);
        this.listbox = new Gtk.ListBox ();
        listbox.selection_mode = Gtk.SelectionMode.NONE;
        this.width_request = 425;

        downloads = new Gee.ArrayList<DownloadDetailBox> ();
        var scroll = new Gtk.ScrolledWindow ();
        scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scroll.min_content_height = 200;
        scroll.set_child(listbox);

        downloads_complete = new Gtk.Label (_ ("No Active Downloads"));
        downloads_complete.get_style_context ().add_class ("h3");
        downloads_complete.sensitive = false;
        //downloads_complete.margin = 12;
        listbox.prepend (downloads_complete);

        set_child(scroll);
    }

    /*
     * Adds a download detail box to the popover listbox
     */
    public void add_download (DownloadDetailBox details) {
        if (downloads.size < 1) {
            hide_downloads_complete ();
        }

        details.ready_for_removal.connect (remove_details_box);
        details.cancel_requested.connect (() => {
            remove_details_box (details);
        });

        downloads.add (details);
        listbox.prepend (details);
        listbox.show();
    }

    private void hide_downloads_complete () {
        //downloads_complete.no_show_all = true;
        downloads_complete.hide ();
    }

    /*
     * Removes a download detail box to the popover listbox
     */
    public void remove_details_box (DownloadDetailBox box) {
        downloads.remove (box);
        box.destroy ();
        if (downloads.size < 1) {
            show_downloads_complete ();
        }
    }

    private void show_downloads_complete () {
        //downloads_complete.no_show_all = false;
        downloads_complete.show();
    }
}

}
