/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public class PlaybackBox : Gtk.Box {

    public signal void scale_changed ();
    public signal void playpause_clicked ();
    public signal void seek_backward_clicked ();
    public signal void seek_forward_clicked ();

    public Gtk.Label episode_label;
    public Gtk.Label podcast_label;
    public Gtk.Button seek_back_button;
    public Gtk.Button playpause_button;
    public Gtk.Button seek_forward_button;
    public Gtk.EventBox artwork;
    public Gtk.Image artwork_image;
    private Gtk.Image play_image;
    private Gtk.Image pause_image;
    private Gtk.ProgressBar progress_bar;
    private Gtk.Scale scale;
    private Gtk.Grid scale_grid;
    private Gtk.Label left_time;
    private Gtk.Label right_time;
    public Gtk.Button volume_button;
    private bool currently_playing = false;

    public PlaybackBox () {
        play_image = new Gtk.Image.from_icon_name("media-playback-start-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        pause_image = new Gtk.Image.from_icon_name("media-playback-pause-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        this.get_style_context ().add_class ("seek-bar");
        orientation = Gtk.Orientation.HORIZONTAL;

        //halign = Gtk.Align.FILL;

        artwork = new Gtk.EventBox ();

        artwork_image = new Gtk.Image.from_icon_name (
            "help-info-symbolic",
            Gtk.IconSize.SMALL_TOOLBAR
        );

        artwork_image.tooltip_text = _("View the shownotes for this episode");
        artwork_image.margin = 12;
        artwork_image.halign = Gtk.Align.START;

        episode_label = new Gtk.Label ("");
        episode_label.set_ellipsize (Pango.EllipsizeMode.END);
        episode_label.xalign = 0.0f;
        episode_label.get_style_context ().add_class ("h3");
        episode_label.max_width_chars = 20;

        podcast_label = new Gtk.Label ("");
        podcast_label.set_ellipsize (Pango.EllipsizeMode.END);
        podcast_label.xalign = 0.0f;
        podcast_label.max_width_chars = 20;

        seek_back_button = new Gtk.Button.from_icon_name (
            "media-seek-backward-symbolic",
            Gtk.IconSize.LARGE_TOOLBAR
        );

        seek_back_button.clicked.connect (() => {
            seek_backward_clicked ();
        });

        playpause_button = new Gtk.Button.from_icon_name (
            "media-playback-start-symbolic",
            Gtk.IconSize.LARGE_TOOLBAR
        );

        playpause_button.clicked.connect (() => {
            playpause_clicked ();
            set_playing (!currently_playing);
        });

        seek_forward_button = new Gtk.Button.from_icon_name (
            "media-seek-forward-symbolic",
            Gtk.IconSize.LARGE_TOOLBAR
        );

        seek_forward_button.clicked.connect (() => {
            seek_forward_clicked ();
        });

        progress_bar = new Gtk.ProgressBar ();

        scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 1, 0.1) {
            hexpand = true,
            draw_value = false,
            halign = Gtk.Align.FILL
        };
        scale.set_value (0.0);
        left_time = new Gtk.Label ("0:00");
        right_time = new Gtk.Label ("0:00");
        left_time.width_chars = 6;
        right_time.width_chars = 6;

        scale.change_value.connect (on_slide);

        scale_grid = new Gtk.Grid () {
            hexpand = true
        };
        scale_grid.valign = Gtk.Align.CENTER;
        scale_grid.halign = Gtk.Align.FILL;

        left_time.margin_end = right_time.margin_start = 3;

        scale_grid.attach (left_time, 0, 0, 1, 1);
        scale_grid.attach (scale, 1, 0, 1, 1);
        scale_grid.attach (right_time, 2, 0, 1, 1);

        //hexpand = true;

        var label_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
        label_box.add (episode_label);
        label_box.add (podcast_label);
        label_box.valign = Gtk.Align.CENTER;
        label_box.halign = Gtk.Align.START;

        var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        button_box.add (seek_back_button);
        button_box.add (playpause_button);
        button_box.add (seek_forward_button);

        volume_button = new Gtk.Button.from_icon_name ("audio-volume-high-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        volume_button.relief = Gtk.ReliefStyle.NONE;
        volume_button.margin_end = 12;

        artwork.add (artwork_image);
        add (artwork);
        add (label_box);
        add (button_box);
        add (scale_grid);
        add (volume_button);
    }

    /*
     * Toggles the icon for the playpause_button
     */
     public void set_playing (bool playing) {
         if (playing) {
             playpause_button.image = pause_image;
             currently_playing = true;
         } else {
             playpause_button.image = play_image;
             currently_playing = false;
         }
     }

    /*
     * Returns the percentage that the progress_bar has been filled
     */
    public double get_progress_bar_fill () {
        return scale.get_value ();
    }

    /*
     * Called when the user slides the slider to change the stream position
     */
    private bool on_slide (Gtk.ScrollType scroll, double new_value) {
        scale.set_value (new_value);
        scale_changed ();
        return false;
    }

    /*
     * Sets the information for the current episode
     */
    public void set_info_title (string episode_title, string podcast_name) {
        episode_label.label = episode_title;
        podcast_label.label = podcast_name;
    }

    /*
     * Sets the progress information for the current stream
     */
    public void set_progress (
        double progress,
        int mins_remaining,
        int secs_remaining,
        int mins_elapsed,
        int secs_elapsed
    ) {
        scale.set_value (progress);

        if (mins_remaining > 59) {
            int hours_remaining = mins_remaining / 60;
            mins_remaining = mins_remaining % 60;
            right_time.set_text ("%02d:%02d:%02d".printf (
                hours_remaining,
                mins_remaining,
                secs_remaining
            ));
        } else {
            right_time.set_text ("%02d:%02d".printf (mins_remaining, secs_remaining));
        }

        if (mins_elapsed > 59) {
            int hours_elapsed = mins_elapsed / 60;
            mins_elapsed = mins_elapsed % 60;
            left_time.set_text ("%02d:%02d:%02d".printf (
                hours_elapsed,
                mins_elapsed,
                secs_elapsed
            ));
        } else {
            left_time.set_text ("%02d:%02d".printf (mins_elapsed, secs_elapsed));
        }

        left_time.no_show_all = false;
        left_time.show ();

        right_time.no_show_all = false;
        right_time.show ();

        scale.no_show_all = false;
        scale.show ();
    }

    public void show_artwork_image () {
        if (artwork_image != null) {
            artwork_image.no_show_all = false;
            artwork_image.show ();
        }
    }

    public void hide_artwork_image () {
        if (artwork_image != null) {
            artwork_image.no_show_all = true;
            artwork_image.hide ();
        }
    }

    public void set_artwork_image (string uri) {
        info ("Setting artwork button to: " + uri);
        artwork_image.clear ();
    	var artwork = GLib.File.new_for_uri (uri);
        var icon = new GLib.FileIcon (artwork);
        artwork_image.gicon = icon;
    	artwork_image.pixel_size = 40;
    }

    public void show_volume_button () {
        if (volume_button != null) {
            volume_button.no_show_all = false;
            volume_button.show ();
        }
    }

    public void hide_volume_button () {
        if (volume_button != null) {
            volume_button.no_show_all = true;
            volume_button.hide ();
        }
    }
}

}
