/*
 * SPDX-License-Identifier: MIT
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leapod {
	public class Controller : GLib.Object {
		public MainWindow window = null;
		public MyApp app = null;
		
		public Controller (MyApp app) {
			info ("initializing the controller.");
			this.app = app;
			
			info ("initializing the main window");
			window = new MainWindow (this);
			
			window.show_all ();
		}
	}
}
