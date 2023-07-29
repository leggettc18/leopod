/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public class MyApp : Gtk.Application {
	public string[] args;
    private Controller controller;

	public MyApp () {
        Object (
            application_id: "com.github.leggettc18.leopod",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        //Granite.Services.Logger.initialize ("Leopod");
        //Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.INFO;

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/leggettc18/leopod/application.css");
        Gtk.StyleContext.add_provider_for_display(
          Gdk.Display.get_default(),
          provider,
          Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        controller = new Controller(this);

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
