/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {
    public class CoverArt : Gtk.Box {
        public Podcast podcast = null;
        public CoverArt.with_podcast (Podcast podcast) {
            this.podcast = podcast;
            //set_size_request (170, 170);
            var controller = new Gtk.GestureClick ();
            controller.released.connect((num_presses, x, y) => {
                    clicked(this.podcast);
                    });
            add_controller (controller);
            orientation = Gtk.Orientation.VERTICAL;
            //no_show_all = true;
            Gtk.Image image = new Gtk.Image () {
                //margin = 0
            };
            Gtk.Label name = new Gtk.Label (podcast.name);
            //name.no_show_all = true;
            //name.margin = 10;
            Gtk.Button button = new Gtk.Button () {
                //always_show_image = true,
                tooltip_text = _("Browse Podcast Episodes"),
                //margin = 0
            };
            button.get_style_context ().add_class ("coverart");

            try {
                //Load the actual coverart
                info (podcast.local_art_uri);
                var file = GLib.File.new_for_uri (podcast.local_art_uri);
                if (!file.query_exists ()) {
                    cache_album_art (podcast);
                    info (podcast.local_art_uri);
                    file = GLib.File.new_for_uri (podcast.local_art_uri);
                }
                image.set_from_file(file.get_path());
                image.pixel_size = 170;
                //button.image = image;
                image.show();
                name.show ();
                show ();
            } catch (Error e) {
                warning ("unable to load podcast coverart.");
            }

            append (image);
            append (name);
        }

        public signal void clicked (Podcast podcast);
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
