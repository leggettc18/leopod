/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leapod {
    public class CoverArt : Gtk.Box {
        public CoverArt.with_podcast (Podcast podcast) {
            Gdk.Pixbuf pixbuf = null;
            Gtk.Image image = null;
            var button = new Gtk.Button () {
                no_show_all = true
            };
            load_image_async.begin (podcast.remote_art_uri, (obj, res) => {
                pixbuf = load_image_async.end (res);
                pixbuf = pixbuf.scale_simple (170, 170, Gdk.InterpType.BILINEAR);
                image = new Gtk.Image.from_pixbuf (pixbuf);
                button.image = image;
                button.show ();
            });
            add (button);
        }
    }
    
    private async Gdk.Pixbuf load_image_async (string url) {
        var soup_client = new SoupClient ();
        return yield new Gdk.Pixbuf.from_stream_async (soup_client.request (HttpMethod.GET, url));
    }
}
