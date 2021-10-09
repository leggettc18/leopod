/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public class Player : ClutterGst.Playback {
    private static Player? player = null;
    public static Player? get_default (string[] args) {
        if (player == null) {
            player = new Player (args);
        }
        return player;
    }
    
    public signal void state_changed (Gst.State new_state);
    public signal void additional_plugins_required (Gst.Message message);
    
    public signal void new_position_available ();
    
    public string tag_string;
    
    public Episode current_episode;
    
    private Player (string[]? args) {
        bool new_launch = true;
        
        current_episode = null;
        
        // Check every half second for playing media and
        // signal new position available if playing
        GLib.Timeout.add (500, () => {
            if (playing) {
                new_position_available ();
            }
            if (new_launch && duration > 0.0) {
                new_position_available();
                new_launch = false;
            }
            return true;
        });
    }
    
    /* Pauses the player */
    public void pause () {
        this.playing = false;
    }
    
    /* Starts the player */
    public void play () {
        this.playing = true;
    }
    
    /*
     * Seeks backward by a number of seconds
     */
    public void seek_backward (int num_seconds) {
        double total_seconds = duration;
        double percentage = num_seconds / total_seconds;
        progress = progress - percentage;
    }
    
    /*
     * Seeks forward by a number of seconds
     */
    public void seek_forward (int num_seconds) {
        double total_seconds = duration;
        double percentage = num_seconds/total_seconds;
        progress = progress + percentage;
    }
    
    /*
     * Sets the episode that is currently being played
     */
    public void set_episode (Episode episode) {
        this.current_episode = episode;
        
        this.uri = episode.playback_uri;
        info ("Setting playback URI: %s", episode.playback_uri);
    }
    
    /*
     * Sets the currently playing media position in seconds
     */
    public void set_position (int seconds) {
        double calculated_progress = (double)seconds / duration;
        progress = calculated_progress;
        new_position_available();
    }
    
    /*
     * Sets the current volume
     */
    public void set_volume (double val) {
        this.audio_volume = val;
    }
    
    /*
     * Gets the current volume
     */
    public double get_volume () {
        return this.audio_volume;
    }
}

}
