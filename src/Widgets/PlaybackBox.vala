/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public class PlaybackBox : Gtk.Box {

    public signal void scale_changed ();
    public signal void seek_backward_clicked ();
    public signal void seek_forward_clicked ();
    public signal void playback_rate_selected (double rate);

    private Gtk.Label episode_label;
    private Gtk.Label podcast_label;
    private Gtk.Button seek_back_button;
    private Gtk.Button playpause_button;
    private Gtk.Button seek_forward_button;
    public Gtk.Box artwork { get; set; }
    private Gtk.Image artwork_image;
    private PlaybackRatePopover playback_rate_popover;
    private Gtk.Image play_image;
    private Gtk.Image pause_image;
    private Gtk.Scale scale;
    private Gtk.Grid scale_grid;
    private Gtk.Label left_time;
    private Gtk.Label right_time;
    private bool currently_playing = false;
    public Application app { get; construct; }

    public PlaybackBox (Application app) {
        Object (app: app);
    }

    construct {
        play_image = new Gtk.Image.from_icon_name ("media-playback-start-symbolic");
        pause_image = new Gtk.Image.from_icon_name ("media-playback-pause-symbolic");
        orientation = Gtk.Orientation.HORIZONTAL;

        artwork = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        artwork_image = new Gtk.Image.from_icon_name (
            "help-info-symbolic"
        );

        artwork_image.tooltip_text = _("View the shownotes for this episode");
        artwork_image.margin_bottom = artwork_image.margin_top =
        artwork_image.margin_start = artwork_image.margin_end = 12;
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

        playback_rate_popover = new PlaybackRatePopover (app.settings.playback_rate);
        playback_rate_popover.rate_selected.connect ((t, r) => {
            playback_rate_selected (r);
        });

        seek_back_button = new Gtk.Button.from_icon_name (
            "media-seek-backward-symbolic"
        ) {
            action_name = "app.seek-backward",
            tooltip_markup = Granite.markup_accel_tooltip (
                app.get_accels_for_action ("app.seek-backward"),
                _("Seek Backward")
            ),
            has_frame = false
        };

        playpause_button = new Gtk.Button.from_icon_name (
            "media-playback-start-symbolic"
        ) {
            action_name = "app.play-pause",
            tooltip_markup = Granite.markup_accel_tooltip (
                app.get_accels_for_action ("app.play-pause"),
                _("Play/Pause")
            ),
            has_frame = false
        };

        seek_forward_button = new Gtk.Button.from_icon_name (
            "media-seek-forward-symbolic"
        ) {
            action_name = "app.seek-forward",
            tooltip_markup = Granite.markup_accel_tooltip (
                app.get_accels_for_action ("app.seek-forward"),
                _("Seek Forward")
            ),
            has_frame = false
        };

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
        scale_grid.margin_end = 10;

        hexpand = true;

        var label_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
        label_box.prepend (episode_label);
        label_box.prepend (podcast_label);
        label_box.valign = Gtk.Align.CENTER;
        label_box.halign = Gtk.Align.START;

        var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        button_box.append (playback_rate_popover);
        button_box.append (seek_back_button);
        button_box.append (playpause_button);
        button_box.append (seek_forward_button);
        button_box.margin_start = 5;

        // volume_button = new Gtk.Button.from_icon_name ("audio-volume-high-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        // volume_button.relief = Gtk.ReliefStyle.NONE;
        // volume_button.margin_end = 12;

        artwork.append (artwork_image);
        append (artwork);
        append (label_box);
        append (button_box);
        append (scale_grid);
        // add (volume_button);
    }

    /*
     * Toggles the icon for the playpause_button
     */
     public void set_playing (bool playing) {
         if (playing) {
             playpause_button.icon_name = "media-playback-start-symbolic";
             currently_playing = true;
         } else {
             playpause_button.icon_name = "media-playback-pause-symbolic";
             currently_playing = false;
         }
     }

     public void toggle_playing () {
         if (!currently_playing) {
             playpause_button.icon_name = "media-playback-pause-symbolic";
             currently_playing = true;
         } else {
             playpause_button.icon_name = "media-playback-start-symbolic";
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

        //left_time.no_show_all = false;
        left_time.show ();

        //right_time.no_show_all = false;
        right_time.show ();

        //scale.no_show_all = false;
        scale.show ();
    }

    public void show_artwork_image () {
        if (artwork_image != null) {
            //artwork_image.no_show_all = false;
            artwork_image.show ();
        }
    }

    public void hide_artwork_image () {
        if (artwork_image != null) {
            //artwork_image.no_show_all = true;
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

}

}
