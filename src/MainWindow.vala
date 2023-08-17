/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public class MainWindow : Gtk.ApplicationWindow {
    // Widgets
    public Application app { private get; construct; }
    public Gtk.HeaderBar header_bar { get; private set; }
    public Gtk.FlowBox all_flowbox { get; private set; }
    public Gtk.ScrolledWindow all_scrolled { get; private set; }
    public PodcastView episodes_box { get; private set; }
    public Gtk.ScrolledWindow episodes_scrolled { get; private set; }
    public Gtk.Button back_button { get; private set; }
    public Gtk.Box main_box { get; private set; }
    public Gtk.Grid main_layout { get; private set; }
    public Granite.OverlayBar overlay_bar { get; private set; }
    public Granite.Placeholder welcome { get; private set; }
    public Gtk.Stack notebook {get; private set; }
    public DeletePodcastDialog delete_podcast { get; private set; }
    public PlaybackBox playback_box { get; private set; }
    public NewEpisodesView new_episodes { get; private set; }

    // Storage of Widgets for navigation
    public Gtk.Widget current_widget { get; private set; }
    public Gtk.Widget previous_widget { get; private set; }

    // Private Widgets
    private Gtk.Overlay overlay;
    private Gtk.Box loading_box;
    private Gtk.Spinner loading_spinner;
    private Granite.Placeholder loading_page;
    private DownloadsWindow downloads;

    // Signals
    public signal void podcast_delete_requested (Podcast podcast);

    public MainWindow (Application app) {
        Object (app: app);
    }

    construct {
        titlebar = new Gtk.Grid () { visible = false };
        overlay = new Gtk.Overlay ();
        overlay_bar = new Granite.OverlayBar (overlay) {
            visible = false,
        };

        app.settings.bind ("width", this, "default_width", SettingsBindFlags.DEFAULT);
        app.settings.bind ("height", this, "default_height", SettingsBindFlags.DEFAULT);
        app.settings.bind ("maximized", this, "maximized", SettingsBindFlags.DEFAULT);
        app.settings.bind ("fullscreen", this, "fullscreened", SettingsBindFlags.DEFAULT);

        var add_podcast_button = new Gtk.Button () {
            child = new Gtk.Image.from_icon_name ("list-add") {
                pixel_size = 24,
            },
            has_frame = false,
            action_name = "app.add-podcast",
            tooltip_markup = Granite.markup_accel_tooltip (
                this.app.get_accels_for_action ("app.add-podcast"),
                _("Add Podcast")
            )
        };

        var download_button = new DownloadsButton (app.download_manager);
        download_button.clicked.connect (show_downloads_window);

        Menu menu = new Menu ();
        menu.append ("Import", "app.import-opml");
        menu.append ("Export", "app.export-opml");
        menu.append ("Quit", "app.quit");

        Gtk.PopoverMenu menu_popover = new Gtk.PopoverMenu.from_model (menu);

        Gtk.MenuButton menu_button = new Gtk.MenuButton () {
            icon_name = "open-menu",
            primary = true,
            tooltip_markup = Granite.markup_accel_tooltip ({"F10"}, _("Menu")),
            popover = menu_popover,
        };
        menu_button.add_css_class (Granite.STYLE_CLASS_LARGE_ICONS);

        header_bar = new Gtk.HeaderBar () {
            show_title_buttons = false,
        };
        header_bar.add_css_class (Granite.STYLE_CLASS_FLAT);
        header_bar.pack_start (new Gtk.WindowControls (Gtk.PackType.START));
        header_bar.pack_end (new Gtk.WindowControls (Gtk.PackType.END));
        header_bar.pack_end (menu_button);
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

        downloads = new DownloadsWindow (app.download_manager);

        this.set_application (app);
        this.set_icon_name ("com.github.leggettc18.leopod");
        title = _("Leopod");

        main_layout = new Gtk.Grid ();
        main_layout.attach (header_bar, 0, 0);

        notebook = new Gtk.Stack () {
            hhomogeneous = vhomogeneous = true,
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT,
            transition_duration = 200,
        };

        // Create a welcome screen and add it to the notebook whether first run or not
        Icon welcome_icon = null;
        Icon welcome_add_icon = null;
        Icon welcome_import_icon = null;
        try {
            welcome_icon = Icon.new_for_string ("leopod-symbolic");
            welcome_add_icon = Icon.new_for_string ("list-add");
            welcome_import_icon = Icon.new_for_string ("document-import");
        } catch (Error e) {
            warning (e.message);
        }
        welcome = new Granite.Placeholder (
            _("Welcome to Leopod")
        ) {
            description = _("Build your library by adding podcasts."),
            icon = welcome_icon,
        };
        var welcome_add_action = welcome.append_button (
            welcome_add_icon,
            _(" Add a new Feed"),
            _(" Provide the web address of a podcast feed.")
        );
        var welcome_import_action = welcome.append_button (
            welcome_import_icon,
            _(" Import an OPML file"),
            _(" Import your podcast feeds from another app")
        );

        welcome_add_action.action_name = "app.add-podcast";
        welcome_import_action.action_name = "app.import-opml";

        // Create the all_scrolled view, which displays all podcasts in a grid.

        all_flowbox = new Gtk.FlowBox () {
            row_spacing = 20,
            column_spacing = 20,
            halign = Gtk.Align.FILL,
            valign = Gtk.Align.START,
            homogeneous = true,
            margin_top = margin_bottom = margin_start = margin_end = 12,
            selection_mode = Gtk.SelectionMode.NONE
        };

        all_flowbox.bind_model (app.library.podcasts, create_coverarts_from_podcasts);

        all_scrolled = new Gtk.ScrolledWindow ();
        all_scrolled.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        all_scrolled.set_child (all_flowbox);

        episodes_scrolled = new Gtk.ScrolledWindow ();
        episodes_scrolled.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);

        new_episodes = new NewEpisodesView (app.library);
        new_episodes.episode_download_requested.connect ((episode) => {
            on_download_requested (episode);
        });
        new_episodes.episode_delete_requested.connect ((episode) => {
            app.library.delete_episode (episode);
        });
        new_episodes.episode_play_requested.connect ((episode) => {
            app.controller.current_episode = episode;
            header_bar.title_widget = new Gtk.Label (episode.title);
            playback_box.set_artwork_image (episode.parent.coverart_uri);
            app.controller.play ();
        });
        var main_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT,
            transition_duration = 200,
            vexpand = true,
            hhomogeneous = vhomogeneous = true,
        };

        main_stack.add_titled (all_scrolled, "all", _("All Podcasts"));
        main_stack.add_titled (new_episodes, "new", _("New Episodes"));

        var main_switcher = new Gtk.StackSwitcher () {
            stack = main_stack,
            halign = Gtk.Align.CENTER,
            margin_top = margin_bottom = margin_start = margin_end = 10
        };

        main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.prepend (main_switcher);
        main_box.append (main_stack);

        loading_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            vexpand = hexpand = true,
            valign = Gtk.Align.CENTER,
        };

        loading_page = new Granite.Placeholder (_("Loading")) {
            valign = halign = Gtk.Align.CENTER,
        };

        loading_spinner = new Gtk.Spinner () {
            spinning = true,
        };

        loading_box.append (loading_page);
        loading_box.append (loading_spinner);

        notebook.add_titled (main_box, "main", _("Main"));
        notebook.add_titled (welcome, "welcome", _("Welcome"));
        notebook.add_titled (episodes_scrolled, "podcast-episodes", _("Episodes"));

        if (app.controller.first_run) {
            main_layout.attach (notebook, 0, 1);
        } else {
            main_layout.attach (loading_box, 0, 1);
        }

        double playback_rate = app.settings.playback_rate;
        app.player.rate = playback_rate;
        playback_box = new PlaybackBox (app);

        playback_box.scale_changed.connect (() => {
            var new_progress = playback_box.get_progress_bar_fill ();
            app.player.progress = new_progress;
        });
        playback_box.playback_rate_selected.connect ((t, r) => {
            app.player.rate = r;
            app.settings.playback_rate = r;
        });
        var gesture_click = new Gtk.GestureClick ();
        playback_box.artwork.add_controller (gesture_click);

        gesture_click.released.connect (() => {
            EpisodeWindow window = new EpisodeWindow (app.controller.current_episode);
            window.show ();
        });

        app.controller.playback_status_changed.connect (() => {
            playback_box.toggle_playing ();
        });

        main_layout.attach (playback_box, 0, 2);

        overlay.child = main_layout;
        child = overlay;

        app.library.library_loaded.connect (on_loaded);
    }

    public void on_loaded () {
        main_layout.remove (loading_box);
        main_layout.attach (notebook, 0, 1);
    }


    public void populate_views () {
        new_episodes.rebuild (app.library);
    }

    /*
     * Populates the views from the contents of the controller.library
     */
    public async void populate_views_async () {
        SourceFunc callback = populate_views_async.callback;
        populate_views ();
        Idle.add ((owned) callback);
        yield;
    }

    /*
     * Handles what happens when a podcast coverart is clicked
     */
    public void on_podcast_clicked (Podcast podcast) {
        switch_visible_page (episodes_scrolled);
        episodes_box = new PodcastView (podcast, notebook.transition_duration);
        episodes_scrolled.set_child (episodes_box);
        episodes_box.episode_download_requested.connect ((episode) => {
            on_download_requested (episode);
        });
        episodes_box.episode_delete_requested.connect ((episode) => {
            app.library.delete_episode (episode);
        });
        episodes_box.episode_play_requested.connect ((episode) => {
            app.controller.current_episode = episode;
            header_bar.title_widget = new Gtk.Label ("%s - %s".printf
            (episode.parent.name, episode.title));
            playback_box.set_artwork_image (episode.parent.coverart_uri);
            app.controller.play ();
        });
        episodes_box.podcast_delete_requested.connect ((podcast) => {
            delete_podcast = new DeletePodcastDialog (this, podcast);
            delete_podcast.response.connect (on_delete_podcast);
            delete_podcast.show ();
        });
        episodes_scrolled.show ();
    }

    private void on_delete_podcast (int response) {
        delete_podcast.destroy ();
        if (response == Gtk.ResponseType.ACCEPT) {
            switch_visible_page (main_box);
            overlay_bar.label = "Deleting Podcast: " + delete_podcast.podcast.name;
            overlay_bar.active = true;
            overlay_bar.show ();
            app.library.delete_podcast.begin (delete_podcast.podcast, (obj, res) => {
                app.library.delete_podcast.end (res);
                overlay_bar.active = false;
                overlay_bar.hide ();
            });
        }
    }

    public void on_download_requested (Episode episode) {
        try {
            app.library.download_episode (episode);
        } catch {
            critical ("LeopodLibraryError");
        }
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
            back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);
            back_button.clicked.connect (() => {
                header_bar.remove (back_button);
                switch_visible_page (back_widget);
            });
            header_bar.pack_start (back_button);
            back_button.show ();
        } else {
            if (back_button != null) {
                header_bar.remove (back_button);
            }
        }
    }

    /*
     * Shows the downloads popover
     */
    public void show_downloads_window () {
        this.downloads.show ();
    }

    private Gtk.Widget create_coverarts_from_podcasts (Object podcast) {
        CoverArt coverart = new CoverArt ((Podcast) podcast);
        coverart.clicked.connect (on_podcast_clicked);
        return coverart;
    }
}

}
