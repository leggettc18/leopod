/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public class ArtworkPopover : Gtk.Popover {
    private Gtk.Label show_notes_label;
    public string show_notes {
        get {
            return show_notes_label.label;
        }

        set {
            show_notes_label.label = Utils.html_to_markup (value);
        }
    }

    public ArtworkPopover (Gtk.Widget parent) {
        set_relative_to (parent);

        var scrolled = new Gtk.ScrolledWindow(null, null);
        var shownotes_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        show_notes_label = new Gtk.Label ("") {
            wrap = true,
            wrap_mode = Pango.WrapMode.WORD,
            use_markup = true,
            margin = 10
        };
        scrolled.set_size_request (400, 200);
        scrolled.add (show_notes_label);
        shownotes_box.add (scrolled);
        add (shownotes_box);
    }
}
}
