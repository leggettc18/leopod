/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leapod {

public class MainWindow : Gtk.Window {
    // Core Components
    private Controller controller;
    private Gtk.FlowBox flowbox;


    public MainWindow (Controller controller) {
        var width = 0, height = 0;
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
        
        flowbox = new Gtk.FlowBox () {
            row_spacing = 20,
            column_spacing = 20,
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.START,
            margin = 10,
        };
        
        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        scrolled_window.add(flowbox);
        add (scrolled_window);

        size_allocate.connect (() => {
            get_size (out width, out height);
            flowbox.set_size_request (width - 20, height - 20);
        });
    }
    
    public void add_podcast (Podcast podcast) {
        var coverart = new CoverArt.with_podcast (podcast);
        flowbox.add (coverart);
    }
    
    public void populate_views () {
        this.controller.library.populate_library ();
        info ("populating main window");
        foreach (Podcast podcast in this.controller.library.podcasts) {
            info ("adding podcast %s", podcast.name);
            add_podcast (podcast);
        }
    }
    
    /*
     * Populates the views from the contents of the controller.library
     */
    public async void populate_views_async () {
        SourceFunc callback = populate_views_async.callback;

        ThreadFunc<void*> run = () => {

            populate_views ();

            Idle.add ((owned) callback);
            return null;
        };

        new Thread<void*> ("populate-views", run);

        yield;
    }
}

}
