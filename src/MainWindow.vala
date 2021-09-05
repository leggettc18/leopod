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
        var label = new Gtk.Label (_("Hello World!"));
        add (label);
     }
 }
