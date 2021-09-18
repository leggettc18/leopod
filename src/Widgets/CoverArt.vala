/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leapod {
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
                always_show_image = true
            };
            load_image_async.begin (podcast.remote_art_uri, (obj, res) => {
                pixbuf = load_image_async.end (res);
                pixbuf = pixbuf.scale_simple (170, 170, Gdk.InterpType.BILINEAR);
                image.set_from_pixbuf(pixbuf);
                button.image = image;
                button.show();
                name.show ();
                show ();
            });
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
}
