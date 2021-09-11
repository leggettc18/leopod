/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leapod {

public class MainWindow : Gtk.Window {
    // Core Components
    private Controller controller;


    public MainWindow (Controller controller) {
        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        // Check if user prefers dark theme or not
        gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

        // Listen for changes to user's dark theme preference
        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme ==
                Granite.Settings.ColorScheme.DARK;
        });

        this.controller = controller;
        this.set_application (controller.app);
        default_height = 600;
        default_width = 1000;
        this.set_icon_name ("com.github.leggettc18.leapod");
        title = _("Leapod");


        var podcast = new Leapod.Podcast.with_remote_art_uri ("http://latenightlinux.com/wp-content/uploads/latenightlinux.jpg");
        var flowbox = new Gtk.FlowBox () {
            column_spacing = 20,
            row_spacing = 20,
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.START,
            orientation = Gtk.Orientation.HORIZONTAL,
            margin = 20
        };
        var button = new Gtk.Button ();
        button.no_show_all = true;
        Gdk.Pixbuf pixbuf = null;
        Gtk.Image image = null;
        load_image_async.begin (podcast.remote_art_uri, (obj, res) => {
            pixbuf = load_image_async.end (res);
            pixbuf = pixbuf.scale_simple (170, 170, Gdk.InterpType.BILINEAR);
            image = new Gtk.Image.from_pixbuf (pixbuf);
            button.image = image;
            button.show ();
        });
        flowbox.add (button);
        button.visible = false;
        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.add(flowbox);
        add (scrolled_window);

        size_allocate.connect ((allocation) => {
            flowbox.set_size_request (allocation.width - 40, allocation.height - 40);
        });
    }

    private async Gdk.Pixbuf load_image_async (string url) {
        var soup_client = new SoupClient ();
        return yield new Gdk.Pixbuf.from_stream_async (soup_client.request (HttpMethod.GET, url));
    }
}

}
