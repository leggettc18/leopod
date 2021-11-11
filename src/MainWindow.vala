/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public class MainWindow : Hdy.ApplicationWindow {
    // Core Components
    private Controller controller;
    public Hdy.HeaderBar header_bar;
    public Gtk.FlowBox all_flowbox;
    public Gtk.ScrolledWindow all_scrolled;
    public PodcastView episodes_box;
    public Gtk.ScrolledWindow episodes_scrolled;
    public Gtk.Button back_button;
    public Gtk.Box main_box;

    private Gee.ArrayList<CoverArt> coverarts;

    public Granite.Widgets.Welcome welcome;
    private Gtk.Stack notebook;

    public AddPodcastDialog add_podcast;
    public PlaybackBox playback_box;
    private DownloadsPopover downloads;
    public NewEpisodesView new_episodes;
    public ArtworkPopover artwork_popover;

    public Gtk.Widget current_widget;
    public Gtk.Widget previous_widget;

    public signal void podcast_delete_requested (Podcast podcast);

    private int width;
    private int height;


    public MainWindow (Controller controller) {
        Hdy.init ();
        width = 0;
        height = 0;
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

        coverarts = new Gee.ArrayList<CoverArt> ();

        var add_podcast_action = new SimpleAction ("add-podcast", null);

        this.controller.app.add_action (add_podcast_action);
        this.controller.app.set_accels_for_action ("app.add-podcast", {"<Control>a"});

        var add_podcast_button = new Gtk.Button.from_icon_name ("list-add", Gtk.IconSize.LARGE_TOOLBAR) {
            action_name = "app.add-podcast",
            tooltip_text = _("Add Podcast")
        };
        var download_button = new Gtk.Button.from_icon_name ("browser-download", Gtk.IconSize.LARGE_TOOLBAR) {
            tooltip_text = _("Downloads")
        };
        download_button.clicked.connect (show_downloads_popover);

        header_bar = new Hdy.HeaderBar () {
            show_close_button = true
        };
        header_bar.pack_end (add_podcast_button);
        header_bar.pack_end (download_button);

        //Only for testing purposes
        // var repopulate_button = new Gtk.Button.from_icon_name ("document-page-setup", Gtk.IconSize.LARGE_TOOLBAR) {
        //     tooltip_text = _("Rebuild UI")
        // };
        // repopulate_button.clicked.connect (() => {
        //     populate_views ();
        // });
        // header_bar.pack_end (repopulate_button);

        downloads = new DownloadsPopover(download_button);

        add_podcast_action.activate.connect (() => {
            on_add_podcast_clicked ();
        });

        this.set_application (controller.app);
        default_height = 600;
        default_width = 1000;
        this.set_icon_name ("com.github.leggettc18.leopod");
        title = _("Leopod");

        Gtk.Grid main_layout = new Gtk.Grid();
        main_layout.attach(header_bar, 0, 0);

        info ("Creating notebook");

        notebook = new Gtk.Stack ();
        notebook.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        notebook.transition_duration = 200;

        info ("Creating welcome screen");
        // Create a welcome screen and add it to the notebook whether first run or not

        welcome = new Granite.Widgets.Welcome (
            _("Welcome to Leopod"),
            _("Build your library by adding podcasts.")
        );
        welcome.append (
            "list-add",
            _("Add a new Feed"),
            _("Provide the web address of a podcast feed.")
        );

        welcome.activated.connect (on_welcome);

        info ("Creating All Scrolled view");
        // Create the all_scrolled view, which displays all podcasts in a grid.

        all_flowbox = new Gtk.FlowBox () {
            row_spacing = 20,
            column_spacing = 20,
            halign = Gtk.Align.FILL,
            valign = Gtk.Align.START,
            margin = 5,
            selection_mode = Gtk.SelectionMode.NONE
        };

        all_scrolled = new Gtk.ScrolledWindow (null, null);
        all_scrolled.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        all_scrolled.add(all_flowbox);


        episodes_scrolled = new Gtk.ScrolledWindow (null, null);
        episodes_scrolled.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);

        new_episodes = new NewEpisodesView (controller.library);
        new_episodes.episode_download_requested.connect ((episode) => {
            DownloadDetailBox detail_box = controller.library.download_episode (episode);
            if (detail_box != null) {
                downloads.add_download (detail_box);
                detail_box.show_all ();
            }

        });
        new_episodes.episode_delete_requested.connect ((episode) => {
            controller.library.delete_episode (episode);
        });
        new_episodes.episode_play_requested.connect ((episode) => {
            controller.current_episode = episode;
            header_bar.title = episode.title;
            playback_box.set_artwork_image (episode.parent.coverart_uri);
            artwork_popover.show_notes = episode.description;
            playback_box.set_playing (true);
            controller.play ();
        });

        var main_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT,
            transition_duration = 200,
            expand = true
        };

        main_stack.add_titled (all_scrolled, "all", _("All Podcasts"));
        main_stack.add_titled (new_episodes, "new", _("New Episodes"));

        var main_switcher = new Gtk.StackSwitcher () {
            stack = main_stack,
            halign = Gtk.Align.CENTER,
            margin = 10
        };

        main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.add (main_switcher);
        main_box.add (main_stack);


        notebook.add_titled (main_box, "main", _("Main"));
        notebook.add_titled (welcome, "welcome", _("Welcome"));
        notebook.add_titled (episodes_scrolled, "podcast-episodes", _("Episodes"));
        notebook.add_titled (new_episodes, "new-episodes", _("New Episodes"));

        main_layout.attach (notebook, 0, 1);

        playback_box = new PlaybackBox ();

        artwork_popover = new ArtworkPopover (playback_box.artwork);

        playback_box.playpause_clicked.connect (()=> {
            controller.play_pause ();
        });
        playback_box.seek_forward_clicked.connect (() => {
            controller.seek_forward ();
        });
        playback_box.seek_backward_clicked.connect (() => {
            controller.seek_backward ();
        });
        playback_box.scale_changed.connect (() => {
            var new_progress = playback_box.get_progress_bar_fill ();
            controller.player.set_progress (new_progress);
        });

        playback_box.artwork.button_press_event.connect (() => {
            this.artwork_popover.show_all ();
            return false;
        });

        main_layout.attach (playback_box, 0, 2);

        var window_handle = new Hdy.WindowHandle ();
        window_handle.add (main_layout);

        add (window_handle);

        add_podcast.response.connect (on_add_podcast);
    }

    public void add_podcast_feed (Podcast podcast) {
        var coverart = new CoverArt.with_podcast (podcast);
        coverart.clicked.connect (on_podcast_clicked);
        coverarts.add (coverart);
        all_flowbox.add (coverart);
    }

    public void populate_views () {
        if (all_flowbox != null) {
            info ("Clearing existing podcast list.");
            for (int i = 0; i < coverarts.size; i++) {
                info ("Removing CoverArt %s", coverarts[i].podcast.name);
                all_flowbox.remove (all_flowbox.get_child_at_index (0));
            }
            coverarts.clear ();
        }
        info ("Adding updated podcast lists.");
        foreach (Podcast podcast in controller.library.podcasts) {
            add_podcast_feed (podcast);
        }
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
     * Handles what happens when a podcast coverart is clicked
     */
    public async void on_podcast_clicked (Podcast podcast) {
        episodes_box = new PodcastView (podcast);
        episodes_scrolled.add (episodes_box);
        episodes_box.episode_download_requested.connect ((episode) => {
            DownloadDetailBox detail_box = controller.library.download_episode (episode);
            if (detail_box != null) {
                downloads.add_download (detail_box);
                detail_box.show_all ();
                downloads.show_all ();
            }

        });
        episodes_box.episode_delete_requested.connect ((episode) => {
            controller.library.delete_episode (episode);
        });
        episodes_box.episode_play_requested.connect ((episode) => {
            controller.current_episode = episode;
            header_bar.title = "%s - %s".printf (episode.parent.name, episode.title);
            playback_box.set_artwork_image (episode.parent.coverart_uri);
            artwork_popover.show_notes = episode.description;
            playback_box.set_playing (true);
            controller.play ();
        });
        episodes_box.podcast_delete_requested.connect ((podcast) => {
            switch_visible_page (main_box);
            podcast_delete_requested (podcast);
        });
        episodes_scrolled.show_all ();
        switch_visible_page(episodes_scrolled);
    }

    /*
     * Called when the main window needs to switch views
     */
    public void switch_visible_page (Gtk.Widget widget) {
        if (current_widget != widget) {
            previous_widget = current_widget;
        }

        if (widget == main_box) {
            notebook.set_visible_child (main_box);
            current_widget = main_box;
        } else if (widget == welcome) {
            notebook.set_visible_child (welcome);
            current_widget = welcome;
        } else if (widget == episodes_scrolled) {
            notebook.set_visible_child (episodes_scrolled);
            current_widget = episodes_scrolled;
        } else if (widget == new_episodes) {
            notebook.set_visible_child (new_episodes);
            current_widget = new_episodes;
        } else {
            info ("Attempted to switch to a page that doesn't exist.");
        }

        // Sets the back_button in certain scenarios
        if ((current_widget != main_box) && (current_widget != welcome)) {
            var back_widget = main_box;
            var back_text = _("All Podcasts");
            if (current_widget == episodes_scrolled) {
                back_widget = main_box;
                back_text = _("All Podcasts");
            }
            back_button = new Gtk.Button () {
                label = back_text,
            };
            back_button.get_style_context ().add_class ("back-button");
            back_button.clicked.connect (() => {
                episodes_scrolled.remove (episodes_box);
                episodes_box.foreach ((child) => episodes_box.remove (child));
                episodes_box.destroy ();
                header_bar.remove (back_button);
                switch_visible_page (back_widget);
            });
            header_bar.pack_start (back_button);
            back_button.show_all ();
        } else {
            if (back_button != null) {
                back_button.destroy ();
            }
        }
    }

    /*
     * Handles responses from the welcome screen
     */
    private void on_welcome (int index) {
        // Add podcast from freed
        if (index == 0) {
            on_add_podcast_clicked ();
        }
    }

    private void on_add_podcast_clicked () {
        add_podcast = new AddPodcastDialog (this);
        add_podcast.response.connect (on_add_podcast);
        add_podcast.show_all ();
    }

    /*
     * Handles adding adding the podcast from the dialog
     */
    public void on_add_podcast (int response_id) {
        if (response_id == Gtk.ResponseType.OK) {
            controller.add_podcast(add_podcast.podcast_uri_entry.get_text ());
        }
        add_podcast.destroy ();
        switch_visible_page (all_scrolled);
    }

    /*
     * Shows the downloads popover
     */
    public void show_downloads_popover () {
        this.downloads.show_all ();
    }
}

}
