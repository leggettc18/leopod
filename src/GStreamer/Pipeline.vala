/*
 * SPDX-License-Identifier: LGPL-3.0.or-later
 * SPDX-FileCopyrightText: 2021 Christopher Leggett <chris@leggett.dev>
 */

namespace Leopod {
public class Pipeline : GLib.Object {
    public Gst.Pipeline pipe;
    public dynamic Gst.Bus bus;
    public Gst.Pad pad;

    public dynamic Gst.Element audiosink;
    public dynamic Gst.Element audiosinkqueue;
    public dynamic Gst.Element playbin;
    public dynamic Gst.Element audiotee;
    public dynamic Gst.Element audiobin;
    public dynamic Gst.Element preamp;

    public Pipeline () {
        pipe = new Gst.Pipeline ("pipeline");
        playbin = Gst.ElementFactory.make ("playbin", "play");

        audiosink = Gst.ElementFactory.make ("autoaudiosink", "audio-sink");

        audiobin = new Gst.Bin ("audiobin");
        audiotee = Gst.ElementFactory.make ("tee", null);
        audiosinkqueue = Gst.ElementFactory.make ("queue", null);

        ((Gst.Bin)audiobin).add_many (audiotee, audiosink);

        audiobin.add_pad (new Gst.GhostPad ("sink", audiotee.get_static_pad ("sink")));

        audiosinkqueue.link_many (audiosink);

        playbin.set ("audio-sink", audiobin);
        bus = playbin.get_bus ();

        Gst.Pad sinkpad = audiosinkqueue.get_static_pad ("sink");
        pad = audiotee.get_request_pad ("src_%u");
        audiotee.set ("alloc-pad", pad);
        pad.link (sinkpad);
    }
}
}