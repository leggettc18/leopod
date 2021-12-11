/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public interface Playback : GLib.Object {
    // Signals
    public signal void new_position_available ();

    // Basic Playback Functions
    public abstract void play ();
    public abstract void pause ();
    public abstract void set_state (Gst.State s);
    public abstract void set_episode (Episode episode);
    public abstract void set_position (int64 pos);
    public abstract int64 get_position ();
    public abstract int64 get_duration ();
    public abstract void set_volume (double val);
    public abstract double get_volume ();
}
}