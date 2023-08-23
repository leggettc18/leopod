/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {
    public class DeletePodcastDialog : Granite.MessageDialog {
        public Gtk.Window parent_window { get; construct; }
        public Podcast podcast { get; construct; }

        public DeletePodcastDialog (Gtk.Window parent, Podcast podcast) {
            Object (
                parent_window: parent,
                podcast: podcast,
                buttons: Gtk.ButtonsType.NONE
            );
        }

        construct {
            transient_for = parent_window;
            set_default_response (Gtk.ResponseType.CANCEL);
            create_widgets ();
        }

        private void create_widgets () {
            // Create and setup widgets
            Icon delete_icon = null;
            try {
                delete_icon = Icon.new_for_string ("dialog-warning");
            } catch (Error e) {
                warning (e.message);
            }

            image_icon = delete_icon;
            primary_text = _("Are you sure you want to unsubscribe from the following podcast? - %s").printf (podcast.name);
            secondary_text = _("This action cannot be undone");

            // Add buttons to button area at the bottom
            add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
            add_button (
                _("Unsubscribe"),
                Gtk.ResponseType.ACCEPT
            ).add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);
            show ();
        }
    }
}
