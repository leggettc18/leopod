/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public class ArtworkPopover : Gtk.Popover {
    private Gtk.Label show_notes_label;
    private Granite.HeaderLabel title_label;
    public string show_notes {
        get {
            return show_notes_label.label;
        }

        set {
            show_notes_label.label = Utils.html_to_markup (value);
        }
    }
    public string title {
        get {
            return title_label.label;
        }
        set {
            title_label.label = value;
        }
    }

    public ArtworkPopover (Gtk.Widget parent) {
        set_parent (parent);

        var scrolled = new Gtk.ScrolledWindow ();
        title_label = new Granite.HeaderLabel ("");
        var shownotes_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        var info_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        show_notes_label = new Gtk.Label ("") {
            wrap = true,
            wrap_mode = Pango.WrapMode.WORD,
            use_markup = true,
            //margin = 10
        };
        scrolled.set_size_request (200, 200);
        scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        info_box.append (title_label);
        info_box.append (show_notes_label);
        scrolled.set_child (info_box);
        scrolled.add_css_class ("padded");
        shownotes_box.prepend (scrolled);
        set_child (shownotes_box);
    }
}
}
