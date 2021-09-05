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
        var soup_client = new SoupClient ();
        var image = new Gdk.Pixbuf.from_stream (soup_client.request (HttpMethod.GET, "https://chrisleggett.me/me.jpg"));
        image = image.scale_simple (170, 170, Gdk.InterpType.BILINEAR);
        var grid = new Gtk.Grid () {
            column_spacing = 6,
            row_spacing = 6,
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER
        };
        var label1 = new Gtk.Label (_("Hello World!"));
        grid.add (label1);
        grid.add (new Gtk.Image.from_pixbuf(image));
        
        add (grid);
     }
 }
