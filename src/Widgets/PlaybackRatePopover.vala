/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public class PlaybackRatePopover : Gtk.Popover {
    public double current_rate = 1.0;
    public double[] rates = {0.5, 0.8, 1.0, 1.2, 1.5, 1.8, 2.0};
    public Gee.ArrayList<Gtk.Button> rate_buttons;
    private Gtk.Box rates_box;

    public signal void rate_selected (double rate);

    public PlaybackRatePopover (Gtk.Widget parent, double? starting_rate = null) {
        set_parent (parent);
        if (starting_rate != null) {
            current_rate = starting_rate;
        }

        rate_buttons = new Gee.ArrayList<Gtk.Button> ();
        rates_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
        int index = 0;
        foreach (double rate in rates) {
            rate_buttons.add (new Gtk.Button.with_label ("x%g".printf (rate)) {
                //relief = Gtk.ReliefStyle.NONE,
                tooltip_text = "x%g".printf (rate),
                can_focus = false
            });
            rate_buttons[index].get_style_context ().add_class ("h3");
            rates_box.prepend (rate_buttons[index]);
            rate_buttons[index].clicked.connect (() => {
                rate_selected (rate);
            });
            index++;
        }
        set_child (rates_box);
    }
}
}
