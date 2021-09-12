/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leapod {
    public class CoverArt : Gtk.Box {
        private bool double_click = false;
        public CoverArt.with_podcast (Podcast podcast) {
            add_events (Gdk.EventMask.BUTTON_RELEASE_MASK);
            orientation = Gtk.Orientation.VERTICAL;
            no_show_all = true;
            Gdk.Pixbuf pixbuf = null;
            Gtk.Image image = null;
            Gtk.Label name = new Gtk.Label (podcast.name);
            name.margin = 5;
            Gtk.Button button = new Gtk.Button ();
            load_image_async.begin (podcast.remote_art_uri, (obj, res) => {
                pixbuf = load_image_async.end (res);
                pixbuf = pixbuf.scale_simple (170, 170, Gdk.InterpType.BILINEAR);
                image = new Gtk.Image.from_pixbuf (pixbuf);
                button.image = image;
                button.show ();
                name.show ();
                show ();
            });
            add (button);
            add (name);
            
            button_release_event.connect ((event) => {
                if (!this.double_click) {
                    clicked (podcast);
                    return true;
                }
                this.double_click = false;
                return false;
            });
            
            button_press_event.connect ((event) => {
                if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                    double_clicked (podcast);
                    this.double_click = true;
                    return true;
                }
                return false;
            });
        }
        
        public signal void clicked (Podcast podcast);
        public signal void double_clicked (Podcast podcast);
    }
    
    private async Gdk.Pixbuf load_image_async (string url) {
        var soup_client = new SoupClient ();
        return yield new Gdk.Pixbuf.from_stream_async (soup_client.request (HttpMethod.GET, url));
    }
}
