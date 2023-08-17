/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public class Application : Gtk.Application {
    public string[] args;
    public LeopodSettings settings { get; private set; }
    public Controller controller { get; private set; }
    public Library library { get; private set; }
    public Player player { get; private set; }
    public DownloadManager download_manager { get; private set; }
    public MainWindow window { get; private set; }

    public SimpleAction add_podcast_action { get; private set; }
    public SimpleAction import_opml_action { get; private set; }
    public SimpleAction export_opml_action { get; private set; }
    public SimpleAction quit_action { get; private set; }
    public SimpleAction play_pause_action { get; private set; }
    public SimpleAction seek_forward_action { get; private set; }
    public SimpleAction seek_backward_action { get; private set; }
    public SimpleAction fullscreen_action { get; private set; }

    public Application () {
        Object (
            application_id: "com.github.leggettc18.leopod",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    construct {
        add_podcast_action = new SimpleAction ("add-podcast", null);
        import_opml_action = new SimpleAction ("import-opml", null);
        export_opml_action = new SimpleAction ("export-opml", null);
        quit_action = new SimpleAction ("quit", null);
        play_pause_action = new SimpleAction ("play-pause", null);
        seek_forward_action = new SimpleAction ("seek-forward", null);
        seek_backward_action = new SimpleAction ("seek-backward", null);
        fullscreen_action = new SimpleAction ("fullscreen", null);

        add_action (add_podcast_action);
        add_action (import_opml_action);
        add_action (export_opml_action);
        add_action (quit_action);
        add_action (play_pause_action);
        add_action (seek_forward_action);
        add_action (seek_backward_action);
        add_action (fullscreen_action);
        set_accels_for_action ("app.add-podcast", { "<Control>a" });
        set_accels_for_action ("app.import-opml", { "<Control><Shift>i" });
        set_accels_for_action ("app.export-opml", { "<Control><Shift>e" });
        set_accels_for_action ("app.quit", { "<Control>q", "<Control>w" });
        set_accels_for_action ("app.play-pause", { "k", "space" });
        set_accels_for_action ("app.seek-forward", { "l" });
        set_accels_for_action ("app.seek-backward", { "h" });
        set_accels_for_action ("app.fullscreen", { "F11"} );
    }

    protected override void activate () {
        base.activate ();
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

        settings = LeopodSettings.get_default_instance ();
        download_manager = new DownloadManager ();
        player = Player.get_default (args);
        library = new Library (this);
        controller = new Controller (this);
        MPRIS mpris = new MPRIS (this);
        mpris.initialize ();
        window = new MainWindow (this);
        window.podcast_delete_requested.connect ((podcast) => {
            library.delete_podcast.begin (podcast, (obj, res) => {
                library.delete_podcast.end (res);
            });
        });
        window.playback_box.hide ();
        window.present ();

        // Add short delay, just long enough for the window to
        // finish animating into view.
        Timeout.add (250, () => {
            controller.post_creation_sequence.begin ();
            return false;
        });
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

        var app = new Application ();
        app.args = args;
        app.run (args);
    }
}

}
