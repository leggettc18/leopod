/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {
    public class LeopodSettings : GLib.Settings {
        private static LeopodSettings _default_instance = null;

        public string library_location { get; set; }
        public double playback_rate {
            get { return get_double ("playback-rate"); }
            set { set_double ("playback-rate", value); }
        }

        public int width {
            get { return get_int ("width"); }
            set { set_int ("width", value); }
        }

        public int height {
            get { return get_int ("height"); }
            set { set_int ("height", value); }
        }

        public bool maximized {
            get { return get_boolean ("maximized"); }
            set { set_boolean ("maximized", value); }
        }

        public bool fullscreen {
            get { return get_boolean ("fullscreen"); }
            set { set_boolean ("fullscreen", value); }
        }

        private LeopodSettings () {
            Object (schema_id: "com.github.leggettc18.leopod");
        }

        public static LeopodSettings get_default_instance () {
            if (_default_instance == null) {
                _default_instance = new LeopodSettings ();
            }

            return _default_instance;
        }
    }
}
