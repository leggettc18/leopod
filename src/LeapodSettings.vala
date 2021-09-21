/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leapod {
    public class LeapodSettings : GLib.Settings {
        private static LeapodSettings _default_instance = null;
        
        public string library_location { get; set; }
        
        private LeapodSettings () {
            base ("com.github.leggettc18.leapod");
        }
        
        public LeapodSettings.get_default_instance () {
            if (_default_instance == null) {
                _default_instance = new LeapodSettings ();
            }
            
            return _default_instance;
        }
    }
}
