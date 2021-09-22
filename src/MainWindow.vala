/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leapod {

public class MainWindow : Gtk.Window {
    // Core Components
    private Controller controller;
    public Gtk.FlowBox all_flowbox;
    public Gtk.ScrolledWindow all_scrolled; 
    
    public Granite.Widgets.Welcome welcome;
    private Gtk.Stack notebook;
    
    public AddPodcastDialog add_podcast;
    
    public Gtk.Widget current_widget;
    public Gtk.Widget previous_widget;


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
        
        info ("Creating notebook");
        
        notebook = new Gtk.Stack ();
        notebook.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        notebook.transition_duration = 200;
        
        info ("Creating welcome screen");
        // Create a welcome screen and add it to the notebook whether first run or not
        
        welcome = new Granite.Widgets.Welcome (
            _("Welcome to Leapod"),
            _("Build your library by adding podcasts.")
        );
        welcome.append (
            "list-add", 
            _("Add a new Feed"), 
            _("Provide the web address of a podcast feed.")
        );
        
        welcome.activated.connect (on_welcome);
        
        info ("Creating All Scrolled view");
        
        all_flowbox = new Gtk.FlowBox () {
            row_spacing = 20,
            column_spacing = 20,
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.START,
            margin = 10,
        };
        
        all_scrolled = new Gtk.ScrolledWindow (null, null);
        all_scrolled.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        all_scrolled.add(all_flowbox);

        size_allocate.connect (() => {
            get_size (out width, out height);
            all_flowbox.set_size_request (width - 20, height - 20);
        });
        
        notebook.add_titled(welcome, "welcome", _("Welcome"));
        notebook.add_titled(all_scrolled, "all", _("All Podcasts"));
        
        add (notebook);
        
        add_podcast.response.connect (on_add_podcast);
    }
    
    public void add_podcast_feed (Podcast podcast) {
        var coverart = new CoverArt.with_podcast (podcast);
        all_flowbox.add (coverart);
        add_podcast.destroy ();
        switch_visible_page (all_scrolled);
    }
    
    public void populate_views () {
        // this.controller.library.populate_library ();
        info ("populating main window");
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

        new Thread<void*> ("populate-views", (owned) run);

        yield;
    }
    
    /*
     * Called when the main window needs to switch views
     */
    public void switch_visible_page (Gtk.Widget widget) {
        if (current_widget != widget) {
            previous_widget = current_widget;
        }
        
        if (widget == all_scrolled) {
            notebook.set_visible_child (all_scrolled);
            current_widget = all_scrolled;
        } else if (widget == welcome) {
            notebook.set_visible_child (welcome);
            current_widget = welcome;
        } else {
            info ("Attempted to switch to a page that doesn't exist.");
        }
    }
    
    /*
     * Handles responses from the welcome screen
     */
    private void on_welcome (int index) {
        // Add podcast from freed
        if (index == 0) {
            add_podcast = new AddPodcastDialog (this);
            add_podcast.response.connect (on_add_podcast);
            add_podcast.show_all ();
        }
    }
    
    /*
     * Handles adding adding the podcast from the dialog
     */
    public void on_add_podcast (int response_id) {
        if (response_id == Gtk.ResponseType.OK) {
            controller.add_podcast(add_podcast.podcast_uri_entry.get_text ());
        }
    }
}

}
