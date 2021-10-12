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
        public signal void delete_requested (Episode episode);
        public signal void play_requested (Episode episode);

        // Constructors
        public EpisodeListItem (Episode episode) {
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

            buttons_box = create_buttons_box ();
            add (buttons_box);
            buttons_box.show_all ();

            episode.download_status_changed.connect (() => {
                buttons_box.destroy ();
                buttons_box = create_buttons_box ();
                add (buttons_box);
                buttons_box.show_all ();
            });
        }

        private Gtk.Box create_buttons_box () {
            buttons_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
                margin = 5
            };
            download_button = new Gtk.Button.from_icon_name (
                "browser-download-symbolic",
                Gtk.IconSize.BUTTON
            ){
            	tooltip_text = _("Download")
            };

            download_button.clicked.connect (() => {
                download_clicked (episode);
            });

            play_button = new Gtk.Button.from_icon_name (
                "media-playback-start-symbolic",
                Gtk.IconSize.BUTTON
            ){
            	tooltip_text = _("Play")
            };
            play_button.clicked.connect (() => {
                play_requested (episode);
            });

            delete_button = new Gtk.Button.from_icon_name (
                "edit-delete-symbolic",
                Gtk.IconSize.BUTTON
            ){
            	tooltip_text = _("Delete")
            };

            delete_button.clicked.connect (() => {
                delete_requested (episode);
            });

            if (episode.current_download_status == DownloadStatus.NOT_DOWNLOADED) {
                buttons_box.pack_start (download_button);
            } else {
                buttons_box.pack_start (play_button);
                buttons_box.pack_end (delete_button);
            }

            return buttons_box;
        }
    }
}
