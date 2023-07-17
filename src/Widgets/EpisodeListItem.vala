/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {
    public class EpisodeListItem : Gtk.Box {
        // Data
        public Episode episode;
        public int desc_lines {
            get {
                return desc.lines;
            }

            set {
                desc.lines = value;
            }
        } //Amount of lines the description is allowed to be.

        // Widgets
        public Gtk.Box buttons_box;
        public Gtk.Box title_box;
        public Gtk.Button info_button;
        public Gtk.Button download_button;
        public Gtk.Button play_button;
        public Gtk.Button delete_button;
        public Gtk.Label title;
        public Gtk.Label desc;

        // Signals
        public signal void download_clicked (Episode episode);
        public signal void delete_requested (Episode episode);
        public signal void play_requested (Episode episode);

        // Constructors
        public EpisodeListItem (Episode episode) {
            margin = 10;
            halign = Gtk.Align.FILL;
            this.episode = episode;
            title_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5) {
                expand = true
            };
            title = new Gtk.Label (episode.title) {
                vexpand = false,
                hexpand = true,
                halign = Gtk.Align.START,
                ellipsize = Pango.EllipsizeMode.END
            };
            title.get_style_context ().add_class ("h3");
            string desc_text = Utils.html_to_markup (episode.description);

            Regex carriageReturns = new Regex ("\\n", RegexCompileFlags.CASELESS);
            desc_text = carriageReturns.replace (desc_text, -1, 0, " ");
            Regex condense_spaces = new Regex ("\\s{2,}");
            desc_text = condense_spaces.replace (desc_text, -1, 0, " ").strip ();
            desc = new Gtk.Label (desc_text) {
            	valign = Gtk.Align.START,
            	max_width_chars = 75,
            	ellipsize = Pango.EllipsizeMode.END,
            	wrap = true,
            	use_markup = true,
            	lines = 3,
            	single_line_mode = true
            };
            title_box.add (title);
            title_box.add (desc);
            add (title_box);

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

            info_button = new Gtk.Button.from_icon_name (
                "dialog-information-symbolic",
                Gtk.IconSize.BUTTON
            ) {
                tooltip_text = _("Description")
            };

            ArtworkPopover show_notes_popover = new ArtworkPopover (info_button);
            show_notes_popover.show_notes = episode.description;

            info_button.clicked.connect (() => {
                show_notes_popover.show_all ();
            });

            download_button = new Gtk.Button.from_icon_name (
                "arrow3-down-symbolic",
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

            buttons_box.pack_start (info_button);
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
