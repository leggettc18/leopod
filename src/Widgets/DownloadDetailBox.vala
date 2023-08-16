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
    private int secs_elapsed;
    private bool download_complete;
    public Download<Episode> download { get; construct; }
    private bool signal_sent;
    private string data_output;
    private string time_output;
    private string outdated_time_output;

    //Constructors
    public DownloadDetailBox (Download download) {
        Object (download: download);
        download.new_percentage_available.connect (() => {
            progress_bar.set_fraction (download.percentage);
            data_output = "%s / %s".printf (
                GLib.format_size (download.bytes_downloaded),
                GLib.format_size (download.bytes_total)
            );
            int time_val_to_display;
            string units;

            if (download.num_secs_remaining > 60) {
                time_val_to_display = download.num_secs_remaining / 60;
                units = ngettext ("minute", "minutes", time_val_to_display);
            } else {
                time_val_to_display = download.num_secs_remaining;
                units = ngettext ("second", "seconds", time_val_to_display);
            }
            time_output = ", about %d %s remaining.".printf (time_val_to_display, units);
            if (outdated_time_output == null) {
                outdated_time_output = time_output;
            }

            download_label.label = data_output + outdated_time_output;
        });
    }

    construct {
        add_css_class (Granite.STYLE_CLASS_BACKGROUND);
        orientation = Gtk.Orientation.VERTICAL;

        secs_elapsed = 0;
        signal_sent = false;
        Episode episode = download.metadata;

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
            download.cancel ();
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

}
}
