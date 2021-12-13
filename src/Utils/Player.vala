/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public class Player : Playback, GLib.Object {
    Pipeline pipe;

    public bool playing;
    private double _rate = 1.0;
    public double rate {
        get {
            return _rate;
        }
        set {
            _rate = value;
            set_position (get_position ());
        }
    }

    public int64 duration {
        get {
            return get_duration ();
        }
    }

    public double progress {
        get {
            return (double) get_position () / get_duration ();
        }
        set {
            set_position ((int64) (value * get_duration ()));
        }
    }

    private static Player? player = null;
    public static Player? get_default (string[] args) {
        if (player == null) {
            player = new Player (args);
        }
        return player;
    }

    public signal void state_changed (Gst.State new_state);
    public signal void additional_plugins_required (Gst.Message message);

    //public signal void new_position_available ();

    public string tag_string;

    public Episode current_episode;

    private Player (string[]? args) {
        bool new_launch = true;
        pipe = new Pipeline ();
        pipe.bus.add_watch (GLib.Priority.DEFAULT, bus_callback);

        current_episode = null;

        // Check every half second for playing media and
        // signal new position available if playing
        GLib.Timeout.add (500, () => {
            if (playing) {
                new_position_available ();
            }
            if (new_launch && get_duration () > 0.0) {
                new_position_available();
                new_launch = false;
            }
            return true;
        });
    }

    public bool set_position (int64 pos) {
        info ("Position: %" + int64.FORMAT, pos);
        return pipe.playbin.seek(_rate, Gst.Format.TIME, Gst.SeekFlags.FLUSH, Gst.SeekType.SET, pos, Gst.SeekType.NONE, get_duration ());
    }

    /* Pauses the player */
    public void pause () {
        playing = false;
        set_state (Gst.State.PAUSED);
    }

    /* Starts the player */
    public void play () {
        playing = true;
        set_state (Gst.State.PLAYING);
    }

    public void set_state (Gst.State s) {
        pipe.playbin.set_state (s);
    }

    /*
     * Seeks backward by a number of seconds
     */
    public bool seek_backward (int64 num_seconds) {
        int64 rv = (int64) 0;
        Gst.Format f = Gst.Format.TIME;

        pipe.playbin.query_position (f, out rv);
        return set_position (rv - (num_seconds * 1000000000));
    }

    /*
     * Seeks forward by a number of seconds
     */
    public bool seek_forward (int64 num_seconds) {
        int64 rv = (int64) 0;
        Gst.Format f = Gst.Format.TIME;

        pipe.playbin.query_position (f, out rv);
        return set_position (rv + (num_seconds * 1000000000));
    }

    /*
     * Sets the episode that is currently being played
     */
    public void set_episode (Episode episode) {
        this.current_episode = episode;
        set_state (Gst.State.READY);
        pipe.playbin.uri = episode.playback_uri;
        GLib.Timeout.add (0, () => {
            var result = set_position (current_episode.last_played_position);
            info (result ? "Seek Succeeded" : "Seek Failed");
            info ("Position: %" + int64.FORMAT, current_episode.last_played_position);
            play ();
            return !result;
        });
    }

    public int64 get_position () {
        int64 rv = (int64) 0;
        Gst.Format f = Gst.Format.TIME;

        pipe.playbin.query_position (f, out rv);

        return rv;
    }

    public int64 get_duration () {
        int64 rv = (int64) 0;
        Gst.Format f = Gst.Format.TIME;

        pipe.playbin.query_duration (f, out rv);

        return rv;
    }

    /*
     * Sets the currently playing media position in seconds
     */
    //  public void set_position (int64 pos) {
    //      info ("Duration: %f, Seconds: %d, Double Seconds: %f", duration, seconds, (double)seconds);
    //      double calculated_progress = (double)seconds / get_duration ();
    //      info ("calculated_progress: %f", calculated_progress);
    //      set_progress (calculated_progress);
    //      new_position_available();
    //  }

    /*
     * Sets the current volume
     */
    public void set_volume (double val) {
        pipe.playbin.set_property ("volume", val);
    }

    
    /*
     * Gets the current volume
     */
    public double get_volume () {
        var val = GLib.Value (typeof (double));
        pipe.playbin.get_property ("volume", ref val);
        return (double)val;
    }

    private bool bus_callback (Gst.Bus bus, Gst.Message message) {
        switch (message.type) {
        case Gst.MessageType.ERROR:
            GLib.Error err;
            string debug;
            message.parse_error (out err, out debug);
            warning ("Error: %s\n", err.message);
            //error_occured ();
            break;
        case Gst.MessageType.ELEMENT:
            //if (message.get_structure () != null && Gst.PbUtils.//is_missing_plugin_message (message) && (dialog == null || !dialog.visible)) {
                //dialog = new InstallGstreamerPluginsDialog (message);
            //}
            break;
        case Gst.MessageType.EOS:
            //end_of_stream ();
            break;
        case Gst.MessageType.STATE_CHANGED:
            Gst.State oldstate;
            Gst.State newstate;
            Gst.State pending;
            message.parse_state_changed (out oldstate, out newstate, out pending);

            if (newstate != Gst.State.PLAYING) {
                break;
            }

            break;
        case Gst.MessageType.TAG:
            Gst.TagList tag_list;

            message.parse_tag (out tag_list);
            if (tag_list != null) {
                if (tag_list.get_tag_size (Gst.Tags.TITLE) > 0) {
                    string title = "";
                    tag_list.get_string (Gst.Tags.TITLE, out title);
                }
            }
            break;
        default:
            break;
        }

        return true;
    }
}

}
