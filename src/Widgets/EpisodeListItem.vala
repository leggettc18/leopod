/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {
    public class EpisodeListItem : Gtk.Box {
        // Data
        public Episode episode { get; construct; }
        public int desc_lines {
            get {
                return desc.lines;
            }

            set {
                desc.lines = value;
            }
        } //Amount of lines the description is allowed to be.
        private string desc_text = null;

        // Widgets
        public Gtk.Box buttons_box;
        public Gtk.Box title_box;
        public Gtk.Button info_button;
        public Gtk.Button download_button;
        public Gtk.Button play_button;
        public Gtk.Button delete_button;
        public Gtk.Label title;
        public Gtk.Label desc;
        private Gtk.Box box;
        private CoverArt coverart;
        public bool show_coverart { get; construct; }

        // Signals
        public signal void download_clicked (Episode episode);
        public signal void delete_requested (Episode episode);
        public signal void play_requested (Episode episode);

        // Constructors
        public EpisodeListItem (Episode episode, bool show_coverart = false) {
            Object (episode: episode, show_coverart: show_coverart);
        }

        construct {
            if (show_coverart) {
                info ("%s, %s", episode.title, episode.parent.name);
                coverart = new CoverArt (episode.parent, false) {
                    margin_end = 6,
                };
                append (coverart);
            }
            box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3) {
                valign = Gtk.Align.CENTER,
                vexpand = true,
                hexpand = true,
                halign = Gtk.Align.FILL,
                valign = Gtk.Align.FILL,
            };
            margin_top = margin_bottom = margin_start = margin_end = 5;
            valign = Gtk.Align.CENTER;
            css_classes = { Granite.STYLE_CLASS_CARD, Granite.STYLE_CLASS_ROUNDED, "padded" };
            append (box);
            orientation = Gtk.Orientation.HORIZONTAL;
            this.episode = episode;
            title_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5) {
                vexpand = true,
                halign = Gtk.Align.FILL,
                margin_top = margin_bottom = margin_start = margin_end = 5,
            };
            title = new Gtk.Label (episode.title) {
                vexpand = false,
                hexpand = true,
                halign = Gtk.Align.FILL,
                max_width_chars = 30,
                ellipsize = Pango.EllipsizeMode.END
            };
            title.get_style_context ().add_class ("h3");
            desc_text = Utils.html_to_markup (episode.description);

            try {
                Regex carriage_returns = new Regex ("\\n", RegexCompileFlags.CASELESS);
                desc_text = carriage_returns.replace (desc_text, -1, 0, " ");
                Regex condense_spaces = new Regex ("\\s{2,}");
                desc_text = condense_spaces.replace (desc_text, -1, 0, " ").strip ();
            } catch (RegexError e) {
                warning (e.message);
            }
            desc = new Gtk.Label (desc_text) {
                valign = Gtk.Align.START,
                max_width_chars = 30,
                ellipsize = Pango.EllipsizeMode.END,
                wrap = true,
                use_markup = true,
                lines = 3,
                single_line_mode = true
            };
            title_box.prepend (title);
            title_box.append (desc);
            box.prepend (title_box);

            buttons_box = create_buttons_box ();
            box.append (buttons_box);

            episode.download_status_changed.connect (() => {
                if (episode.current_download_status == DownloadStatus.NOT_DOWNLOADED) {
                    buttons_box.remove (play_button);
                    buttons_box.remove (delete_button);
                    buttons_box.append (download_button);
                } else {
                    buttons_box.remove (download_button);
                    buttons_box.append (play_button);
                    buttons_box.append (delete_button);
                }
            });
        }

        private Gtk.Box create_buttons_box () {
            buttons_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
                margin_top = 10,
                margin_bottom = 10,
                vexpand = false,
                hexpand = true,
                halign = Gtk.Align.FILL,
            };

            info_button = new Gtk.Button.from_icon_name (
                "dialog-information-symbolic"
            ) {
                tooltip_text = _("Description"),
                hexpand = true,
                has_frame = true,
                css_classes = { "episode-button" }
            };

            info_button.clicked.connect (() => {
                EpisodeWindow window = new EpisodeWindow (episode);
                window.show ();
            });

            download_button = new Gtk.Button.from_icon_name (
                "folder-download-symbolic"
            ) {
                hexpand = true,
                tooltip_text = _("Download"),
                has_frame = true,
                css_classes = { "episode-button" },
            };

            download_button.clicked.connect (() => {
                download_clicked (episode);
            });

            play_button = new Gtk.Button.from_icon_name (
                "media-playback-start-symbolic"
            ) {
                tooltip_text = _("Play"),
                hexpand = true,
                has_frame = true,
                css_classes = { "episode-button" },
            };
            play_button.clicked.connect (() => {
                play_requested (episode);
            });

            delete_button = new Gtk.Button.from_icon_name (
                "user-trash-symbolic"
            ) {
                tooltip_text = _("Delete"),
                hexpand = true,
                has_frame = true,
                css_classes = { "episode-button" },
            };

            delete_button.clicked.connect (() => {
                delete_requested (episode);
            });

            buttons_box.prepend (info_button);
            if (episode.current_download_status == DownloadStatus.NOT_DOWNLOADED) {
                buttons_box.append (download_button);
            } else {
                buttons_box.append (play_button);
                buttons_box.append (delete_button);
            }

            return buttons_box;
        }
    }
}
