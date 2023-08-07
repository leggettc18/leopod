/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public class DownloadDetailBox : Gtk.Box {
    //Signals
    public signal void cancel_requested (Episode episode);
    public signal void download_completed (Episode e);
    //Usually fired when download has ended, successful or not.
    public signal void ready_for_removal (DownloadDetailBox box);
    public signal void new_percentage_available ();

    //Widgets
    private Gtk.Label title_label;
    private Gtk.Label podcast_label;
    private Gtk.ProgressBar progress_bar;
    private Gtk.Label download_label;

    //State Data
    private double percentage;
    private int secs_elapsed;
    private bool download_complete;
    public Episode episode { get; construct; }
    private bool signal_sent;
    private string data_output;
    private string time_output;
    private string outdated_time_output;

    //Constructors
    public DownloadDetailBox (Episode episode) {
        Object (episode: episode);
    }

    construct {
        add_css_class (Granite.STYLE_CLASS_BACKGROUND);
        orientation = Gtk.Orientation.VERTICAL;

        secs_elapsed = 0;
        signal_sent = false;

        //Load coverart
        var file = GLib.File.new_for_uri (episode.parent.coverart_uri);
        var icon = new GLib.FileIcon (file);
        var image = new Gtk.Image.from_gicon (icon);
        image.pixel_size = 64;

        //Spacing
        //margin = 5;
        //margin_left = margin_right = 12;
        //spacing = 5;

        //Title Label
        title_label = new Gtk.Label (episode.title.replace ("%27", "'"));
        title_label.justify = Gtk.Justification.RIGHT;
        title_label.xalign = 0;
        title_label.max_width_chars = 15;

        //Podcast Label
        podcast_label = new Gtk.Label (episode.parent.name.replace ("%27", "'"));
        podcast_label.justify = Gtk.Justification.LEFT;
        podcast_label.xalign = 0;
        podcast_label.max_width_chars = 15;

        //Label Box
        var label_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
        label_box.append (podcast_label);
        label_box.append (title_label);

        //Details Box
        var details_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        details_box.append (image);
        details_box.append (label_box);

        //Progress Bar and cancel button (and containing Box)
        var progress_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);

        progress_bar = new Gtk.ProgressBar ();
        progress_bar.show_text = false;
        progress_bar.hexpand = true;
        progress_bar.valign = Gtk.Align.CENTER;

        var cancel_button = new Gtk.Button.from_icon_name (
            "process-stop-symbolic"
        ) {
            tooltip_text = _("Cancel Download")
        };
        cancel_button.get_style_context ().add_class ("flat");
        cancel_button.tooltip_text = _("Cancel Download");
        cancel_button.clicked.connect (() => {
            cancel_requested (this.episode);
        });

        progress_box.append (progress_bar);
        progress_box.append (cancel_button);

        //Download Label
        download_label = new Gtk.Label ("");
        download_complete = false;
        download_label.xalign = 0;

        //Add it all together.
        label_box.append (progress_box);
        label_box.append (download_label);
        append (details_box);

        //Keep track of seconds elapsed.
        GLib.Timeout.add (1000, () => {
            secs_elapsed += 1;
            return !download_complete;
        });

        // Update the variable that gets set during a download via the
        // download_delegate function each second.
        GLib.Timeout.add (1000, () => {
            outdated_time_output = time_output;
            return !download_complete;
        });
    }

    /*
     * Sets download progress as the download progresses. Intended to be called
     * as the FileProgressCallback delegate function in a GLib.File.copy
     * call.
     */
    public void download_delegate (int64 current_num_bytes, int64 total_num_bytes) {
        //If download is complete and necessary signals have not been sent yet.
        if (current_num_bytes == total_num_bytes && !signal_sent) {
            //Set percentage to 100% and send new percentage available signal
            //for any listensers.
            percentage = 1.0;
            download_completed (episode);
            ready_for_removal (this);
            signal_sent = true;
            new_percentage_available ();
            return;
        }

        percentage = ((double)current_num_bytes / (double)total_num_bytes);
        double mb_downloaded = (double) current_num_bytes / 1000000;
        double mb_total = (double) total_num_bytes / 1000000;
        double mb_remaining = mb_total - mb_downloaded;

        progress_bar.set_fraction (percentage);

        double mbps = mb_downloaded / secs_elapsed;

        int num_secs_remaining = (int) (mb_remaining / mbps);
        int time_val_to_display;
        string units;

        if (num_secs_remaining > 60) {
            time_val_to_display = num_secs_remaining / 60;
            units = ngettext ("minute", "minutes", time_val_to_display);
        } else {
            time_val_to_display = num_secs_remaining;
            units = ngettext ("second", "seconds", time_val_to_display);
        }

        data_output = "%s / %s".printf (
            GLib.format_size (current_num_bytes),
            GLib.format_size (total_num_bytes)
        );
        time_output = """, about %d %s remaining.""".printf (time_val_to_display, units);

        //Always use the "outdated" time when setting the label.
        //A timer (see constructor) updates this value every second,
        //which is much less jarring than how often this will be called.

        if (outdated_time_output == null) {
            outdated_time_output = time_output;
        }

        download_label.label = data_output + outdated_time_output;

        new_percentage_available ();
    }
}

}
