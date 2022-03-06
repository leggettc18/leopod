/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {
    public class AddPodcastDialog : Granite.Dialog {
        public Gtk.Entry podcast_uri_entry;
        private Gtk.Widget add_podcast_button;

        public AddPodcastDialog (Gtk.Window parent) {
            set_transient_for (parent);
            set_default_response (Gtk.ResponseType.ACCEPT);
            create_widgets ();
        }

        private void create_widgets () {
            // Create and setup widgets
            this.podcast_uri_entry = new Gtk.Entry () {
                width_request = 300,
            };
            var add_label = new Gtk.Label.with_mnemonic(_("Podcast RSS Feed URL"));
            add_label.mnemonic_widget = this.podcast_uri_entry;

            // Layout Widgets
            var hbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
                margin_start = 12,
                margin_end = 12
            };
            hbox.pack_start(add_label, false, true, 0);
            hbox.pack_start(this.podcast_uri_entry, true, true, 0);
            var content = get_content_area ();
            content.add (hbox);

            // Add buttons to button area at the bottom
            add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
            this.add_podcast_button = add_button (_("Add"), Gtk.ResponseType.ACCEPT);
            this.add_podcast_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            this.add_podcast_button.sensitive = false;

            podcast_uri_entry.changed.connect (() => {
                if (podcast_uri_entry.text != "") {
                    add_podcast_button.sensitive = true;
                }
            });

            show_all ();
        }
    }
}
