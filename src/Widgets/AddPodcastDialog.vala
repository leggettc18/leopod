/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {
    public class AddPodcastDialog : Gtk.Dialog {
        public Gtk.Entry podcast_uri_entry;
        private Gtk.Widget add_podcast_button;
        
        public AddPodcastDialog (Gtk.Window parent) {
            this.title = _("Add Podcast");
            set_transient_for (parent);
            set_attached_to (parent);
            set_modal (true);
            set_resizable (false);
            set_default_response (Gtk.ResponseType.OK);
            this.border_width = 5;
            set_default_size (500, 150);
            create_widgets ();
        }
        
        private void create_widgets () {
            // Create and setup widgets
            this.podcast_uri_entry = new Gtk.Entry ();
            var add_label = new Gtk.Label.with_mnemonic(_("Podcast RSS Feed URL:"));
            add_label.mnemonic_widget = this.podcast_uri_entry;
            
            // Layout Widgets
            var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 20);
            hbox.pack_start(add_label, false, true, 0);
            hbox.pack_start(this.podcast_uri_entry, true, true, 0);
            var content = get_content_area () as Gtk.Box;
            content.pack_start(hbox, false, true, 0);
            content.spacing = 10;
            
            // Add buttons to button area at the bottom
            add_button (_("Close"), Gtk.ResponseType.CLOSE);
            this.add_podcast_button = add_button (_("Add"), Gtk.ResponseType.OK);
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
