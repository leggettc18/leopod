/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leapod {

public class MyApp : Gtk.Application {
	public MyApp () {
        Object (
            application_id: "com.github.leggettc18.leapod",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var controller = new Controller(this);
    }

    public static int main (string[] args) {
        return new MyApp ().run (args);
    }
}

}
