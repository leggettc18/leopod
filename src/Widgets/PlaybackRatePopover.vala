/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public class PlaybackRatePopover : Gtk.Widget {
    private Gtk.PopoverMenu popover_menu;
    private Menu menu;
    private Gtk.Button button;
    public double rate { get; construct; }
    public double[] rates = {0.5, 0.8, 1.0, 1.2, 1.5, 1.8, 2.0};
    public Gee.ArrayList<Gtk.Button> rate_buttons;

    public signal void rate_selected (double rate);

    public PlaybackRatePopover (double rate = 1.0) {
        Object (rate: rate);
    }

    construct {
        layout_manager = new Gtk.BinLayout ();
        menu = new Menu ();
        button = new Gtk.Button.with_label ("x%.1f".printf (rate)) {
            tooltip_text = _("Playback Rate"),
            has_frame = false,
        };
        button.clicked.connect (() => {
            popover_menu.show ();
        });
        button.add_css_class (Granite.STYLE_CLASS_H3_LABEL);
        foreach (double rate in rates) {
            var menu_item = new MenuItem ("%.1f".printf (rate), null);
            menu_item.set_attribute ("custom", "s", "%.1f".printf (rate));
            menu.append_item (menu_item);
        }
        popover_menu = new Gtk.PopoverMenu.from_model (menu);
        rate_buttons = new Gee.ArrayList<Gtk.Button> ();
        int index = 0;
        foreach (double rate in rates) {
            rate_buttons.add (new Gtk.Button.with_label ("x%.1f".printf (rate)) {
                has_frame = false,
                tooltip_text = "x%.1f".printf (rate),
            });
            rate_buttons[index].add_css_class (Granite.STYLE_CLASS_H3_LABEL);
            popover_menu.add_child (rate_buttons[index], "%.1f".printf (rate));
            rate_buttons[index].clicked.connect (() => {
                popover_menu.popdown ();
                this.rate = rate;
                button.label = "x%.1f".printf (rate);
                rate_selected (rate);
            });
            index++;
        }
        popover_menu.set_parent (button);
        button.set_parent (this);
    }
}
}
