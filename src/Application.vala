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
        Granite.Services.Logger.initialize ("Leapod");
        Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.INFO;
        info ("Starting activation");
        
        var controller = new Controller(this);
        
    }

    public static int main (string[] args) {
        return new MyApp ().run (args);
    }
}

}
