/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leapod {
    public class AddPodcastDialog : Gtk.Dialog {
        private Gtk.Entry podcast_uri_entry;
        private Gtk.Widget add_podcast_button;
        private Controller controller;
        
        public AddPodcastDialog (Controller controller) {
            this.title = "Add Podcast";
            this.controller = controller;
            this.border_width = 5;
            set_default_size (500, 100);
            create_widgets ();
            connect_signals ();
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
            this.add_podcast_button = add_button (_("Add"), Gtk.ResponseType.APPLY);
            this.add_podcast_button.sensitive = false;
            
            show_all ();
        }
        
        private void connect_signals () {
            this.podcast_uri_entry.changed.connect (() => {
                this.add_podcast_button.sensitive = (this.podcast_uri_entry.text != "");
            });
            this.response.connect (on_response);
        }
        
        private void on_response (Gtk.Dialog source, int response_id) {
            switch (response_id) {
                case Gtk.ResponseType.CLOSE:
                    destroy ();
                    break;
                case Gtk.ResponseType.APPLY:
                    this.controller.add_podcast_async.begin (this.podcast_uri_entry.text);
                    destroy ();
                    break;
            }
        }
    }
}
