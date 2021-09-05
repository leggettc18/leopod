/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

 public class MainWindow : Gtk.Window {
     public MainWindow (Gtk.Application application) {
         Object (
             application: application,
             height_request: 600,
             width_request: 1000,
             icon_name: "com.github.leggettc18.leapod",
             title: _("Leapod")

         );
     }

     construct {
        var grid = new Gtk.Grid () {
            column_spacing = 6,
            row_spacing = 6,
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER
        };
        var label1 = new Gtk.Label (_("Hello World!"));
        var label2 = new Gtk.Label (_("Hello World Again!"));
        grid.add (label1);
        grid.add (label2);
        add (grid);
     }
 }
