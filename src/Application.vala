/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {

public class MyApp : Gtk.Application {
	public MyApp () {
        Object (
            application_id: "com.github.leggettc18.leopod",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        Granite.Services.Logger.initialize ("Leopod");
        Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.INFO;
        info ("Starting activation");

        var controller = new Controller(this);

    }

    public static int main (string[] args) {
        return new MyApp ().run (args);
    }
}

}
