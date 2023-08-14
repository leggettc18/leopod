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
