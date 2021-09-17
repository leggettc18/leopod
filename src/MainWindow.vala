/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leapod {

public class MainWindow : Gtk.Window {
    // Core Components
    private Controller controller;
    private Gee.ArrayList<Podcast> podcasts;
    private Gtk.FlowBox flowbox;


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
        
        podcasts = new Gee.ArrayList<Podcast> ();

        podcasts.add (new FeedParser ().get_podcast_from_file ("https://latenightlinux.com/feed/mp3"));
        podcasts.add (new FeedParser ().get_podcast_from_file ("https://feeds.fireside.fm/linuxunplugged/rss"));
        podcasts.add (new FeedParser ().get_podcast_from_file ("https://feeds.fireside.fm/coder/rss"));
        flowbox = new Gtk.FlowBox () {
            column_spacing = 20,
            row_spacing = 20,
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.START,
            orientation = Gtk.Orientation.HORIZONTAL,
            margin = 20
        };
        for (var i = 0; i < 3; i++) {
            add_podcast (podcasts[i]);
        }
        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.add(flowbox);
        add (scrolled_window);

        size_allocate.connect ((allocation) => {
            flowbox.set_size_request (allocation.width - 40, allocation.height - 40);
        });
    }
    
    public void add_podcast (Podcast podcast) {
        var coverart = new CoverArt.with_podcast (podcast);
        flowbox.add (coverart);
    }
}

}
