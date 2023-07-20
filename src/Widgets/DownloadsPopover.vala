/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public class DownloadsPopover : Gtk.Popover {
    private Gtk.Box box;
    private Gtk.ListBox listbox;
    private Gtk.Label downloads_complete;
    public ObservableArrayList<DownloadDetailBox> downloads;

    private Gtk.Widget CreateDownloadDetailBox(GLib.Object object) {
        return (DownloadDetailBox) object;
    }

    public DownloadsPopover (Gtk.Widget parent) {
        this.set_parent(parent);
        this.box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
            valign = Gtk.Align.CENTER
        };
        this.listbox = new Gtk.ListBox ();
        listbox.selection_mode = Gtk.SelectionMode.NONE;
        listbox.get_style_context().add_class("download-details");
        this.width_request = 425;

        downloads = new ObservableArrayList<DownloadDetailBox> ();
        listbox.bind_model(downloads, CreateDownloadDetailBox);
        var scroll = new Gtk.ScrolledWindow ();
        scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scroll.min_content_height = 200;
        scroll.set_child(box);
        box.append(listbox);

        downloads_complete = new Gtk.Label (_ ("No Active Downloads"));
        downloads_complete.get_style_context ().add_class ("h3");
        downloads_complete.sensitive = false;
        //downloads_complete.margin = 12;
        box.prepend (downloads_complete);

        set_child(scroll);
    }

    /*
     * Adds a download detail box to the popover listbox
     */
    public void add_download (DownloadDetailBox details) {
        hide_downloads_complete ();

        details.ready_for_removal.connect (() => {
            remove_details_box(details);
        });
        details.cancel_requested.connect (() => {
            remove_details_box (details);
        });
        
        downloads.add (details);
        listbox.bind_model(downloads, CreateDownloadDetailBox);
        listbox.show();
    }

    private void hide_downloads_complete () {
        //downloads_complete.no_show_all = true;
        downloads_complete.set_visible(false);
    }

    /*
     * Removes a download detail box to the popover listbox
     */
    public void remove_details_box (DownloadDetailBox box) {
        downloads.remove (box);
        listbox.bind_model(downloads, CreateDownloadDetailBox);
        if (downloads.size < 1) {
            show_downloads_complete();
        }
    }

    private void show_downloads_complete () {
        //downloads_complete.no_show_all = false;
        downloads_complete.set_visible(true);
    }
}

}
