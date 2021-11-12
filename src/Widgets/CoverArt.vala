/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {
    public class CoverArt : Gtk.Box {
        private bool double_click = false;
        public Podcast podcast = null;
        public CoverArt.with_podcast (Podcast podcast) {
            this.podcast = podcast;
            set_size_request (170, 170);
            add_events (Gdk.EventMask.BUTTON_RELEASE_MASK | Gdk.EventMask.BUTTON_PRESS_MASK);
            orientation = Gtk.Orientation.VERTICAL;
            no_show_all = true;
            Gdk.Pixbuf pixbuf = null;
            Gtk.Image image = new Gtk.Image ();
            Gtk.Label name = new Gtk.Label (podcast.name);
            name.no_show_all = true;
            name.margin = 5;
            Gtk.Button button = new Gtk.Button () {
                always_show_image = true,
                tooltip_text = _("Browse Podcast Episodes")
            };

            try {
                //Load the actual coverart
                info (podcast.local_art_uri);
                var file = GLib.File.new_for_uri (podcast.local_art_uri);
                if (!file.query_exists ()) {
                    cache_album_art (podcast);
                    info (podcast.local_art_uri);
                    file = GLib.File.new_for_uri (podcast.local_art_uri);
                }
                var icon = new GLib.FileIcon (file);
                image = new Gtk.Image.from_gicon (icon, Gtk.IconSize.DIALOG);
                image.pixel_size = 170;
                button.image = image;
                button.show ();
                name.show ();
                show ();
            } catch (Error e) {
                warning ("unable to load podcast coverart.");
            }

            add (button);
            add (name);
        }

        public override bool button_release_event(Gdk.EventButton event) {
            if (!this.double_click) {
                clicked (this.podcast);
                return false;
            }
            this.double_click = false;
            return false;
        }

        public override bool button_press_event (Gdk.EventButton event) {
            if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                double_clicked (this.podcast);
                this.double_click = true;
                return false;
            }
            return false;
        }

        public signal void clicked (Podcast podcast);
        public signal void double_clicked (Podcast podcast);
    }

    private async Gdk.Pixbuf load_image_async (string url) {
        var soup_client = new SoupClient ();
        return yield new Gdk.Pixbuf.from_stream_async (soup_client.request (HttpMethod.GET, url));
    }

    /*
     * Downloads and Caches a podcast's album art if it doesn't
     * already exist.
     */
     private void cache_album_art (Podcast podcast) {
	    // Set the local library directory and replace ~ with absolute path
	    string local_library_path = GLib.Environment.get_user_data_dir () + """/leopod""";
	    local_library_path = local_library_path.replace (
	        "~",
	        GLib.Environment.get_home_dir ()
	    );

         string podcast_path = local_library_path + "/%s".printf (
	        podcast.name.replace ("%27", "'").replace ("%", "_")
	    );

	    // Create a directory for downloads and artwork caching
	    GLib.DirUtils.create_with_parents (podcast_path, 0775);

	    // Locally cache the album art if necessary
	    try {
	        // Don't user the coverart_path getter, use the remote_uri
	        GLib.File remote_art = GLib.File.new_for_uri (podcast.remote_art_uri);
	        if (remote_art.query_exists ()) {
	            // If the remote art exists, set path for new file and create object for the local file
	            string art_path = podcast_path + "/" + remote_art.get_basename ().replace ("%", "_");
	            info (art_path);
	            GLib.File local_art = GLib.File.new_for_path (art_path);

	            if (!local_art.query_exists ()) {
	                // Cache the art
	                remote_art.copy (local_art, FileCopyFlags.NONE);
	            }
	            // Mark the local path on the podcast
	            podcast.local_art_uri = "file://" + art_path;
	        }
	    } catch (Error e) {
	        error ("unable to save a local copy of album art. %s", e.message);
	    }
     }

}
