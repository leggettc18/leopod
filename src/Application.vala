/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public class MyApp : Gtk.Application {
    public string[] args;
    public GLib.Settings settings { get; private set; }
    public Controller controller { get; private set; }

    public MyApp () {
        Object (
            application_id: "com.github.leggettc18.leopod",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();
        // Check if user prefers dark theme or not
        gtk_settings.gtk_application_prefer_dark_theme =
            granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        // Listen for changes to user's dark theme preference
        granite_settings.notify["prefers-color-scheme"].connect (() => {
                gtk_settings.gtk_application_prefer_dark_theme =
                    granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/leggettc18/leopod/application.css");
        Gtk.StyleContext.add_provider_for_display (
          Gdk.Display.get_default (),
          provider,
          Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        settings = new GLib.Settings ("com.github.leggettc18.leopod");
        controller = new Controller (this);

    }

    public static void main (string[] args) {

        // Initialize Clutter
        //  var err = Clutter.init (ref args);
        //  if (err != Clutter.InitError.SUCCESS) {
        //      stdout.puts ("Cloud not initialize clutter.\n");
        //      error ("Could not initialize clutter! " + err.to_string ());
        //  }

        // Initialize GStreamer
        Gst.init (ref args);
        //Gst.PbUtils.init ();

        // Set the media role
        GLib.Environ.set_variable ({"PULSE_PROP_media.role"}, "audio", "true");

        var app = new MyApp ();
        app.args = args;
        app.run (args);
    }
}

}
