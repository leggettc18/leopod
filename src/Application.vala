/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leapod {

public class MyApp : Gtk.Application {
    public Gtk.HeaderBar header_bar;
	public MyApp () {
        Object (
            application_id: "com.github.leggettc18.leapod",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var add_podcast_action = new SimpleAction ("add-podcast", null);
        
        add_action (add_podcast_action);
        set_accels_for_action ("app.add-podcast", {"<Control>a"});
        
        var button = new Gtk.Button.from_icon_name ("list-add", Gtk.IconSize.LARGE_TOOLBAR) {
            action_name = "app.add-podcast"
        };
        
        header_bar = new Gtk.HeaderBar () {
            show_close_button = true
        };
        header_bar.pack_end (button);
        
    
        var controller = new Controller(this);
        
        add_podcast_action.activate.connect (() => {
            new AddPodcastDialog (controller).show ();
        });
    }

    public static int main (string[] args) {
        return new MyApp ().run (args);
    }
}

}
