/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {
    public class EpisodeListItem : Gtk.Box {
        // Data
        public Episode episode;

        // Widgets
        public Gtk.Box buttons_box;
        public Gtk.Button download_button;
        public Gtk.Button play_button;
        public Gtk.Button delete_button;
        public Gtk.Label title;
        
        // Signals
        public signal void download_clicked (Episode episode);

        // Constructors
        public EpisodeListItem (Episode episode) {
            info ("%s: %s", episode.title, episode.current_download_status.to_string ());
            add_events (
                Gdk.EventMask.ENTER_NOTIFY_MASK |
                Gdk.EventMask.LEAVE_NOTIFY_MASK
            );
            margin_right = 10;
            halign = Gtk.Align.FILL;
            this.episode = episode;
            title = new Gtk.Label (episode.title) {
                expand = true,
                halign = Gtk.Align.START
            };
            add (title);
            download_button = new Gtk.Button.from_icon_name (
                "browser-download-symbolic",
                Gtk.IconSize.BUTTON
            );
            play_button = new Gtk.Button.from_icon_name (
                "media-playback-start-symbolic",
                Gtk.IconSize.BUTTON
            );
            delete_button = new Gtk.Button.from_icon_name (
                "edit-delete-symbolic",
                Gtk.IconSize.BUTTON
            );

            buttons_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
               margin = 5
            };
            if (this.episode.current_download_status == DownloadStatus.NOT_DOWNLOADED) {
                buttons_box.pack_start (download_button);
                download_button.clicked.connect (() => {
                    download_clicked (episode);
                });
            } else if (this.episode.current_download_status == DownloadStatus.DOWNLOADED){
                buttons_box.pack_start (play_button);
                buttons_box.pack_end (delete_button);
            }
            add (buttons_box);
            buttons_box.show ();
        }
    }
}
