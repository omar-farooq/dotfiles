pragma Singleton

// Everything the bar knows about PipeWire, in one place.
//
// The volume pill used to talk to Pipewire directly, which was fine while the
// only question was "how loud is the default sink". The mixer asks three more
// -- which outputs exist, which one is default, and what is playing -- and both
// it and the pill have to agree on the answers, so they come from here.
//
// Node labels are assembled from `nickname`/`description`/`name` rather than
// from PipeWire properties like `application.name`: Quickshell exposes
// `PwNode.properties`, but on this machine it is an empty map for every node,
// sinks and streams alike.

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    // The default output.
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null

    readonly property int volume: audio ? Math.round(audio.volume * 100) : 0
    readonly property bool muted: audio ? audio.muted : false

    // The output devices to choose between: sinks that are not streams.
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream)

    // Applications currently playing.
    //
    // `isSink` here is the opposite way round from the obvious reading, and
    // getting it backwards lists precisely the wrong things. The flags describe
    // the *graph*, not the application: a browser playing a video owns a stream
    // that audio flows into on its way to a speaker, so that stream is a sink
    // (`isStream && isSink`). cava, which reads the output monitor to draw its
    // bars, owns a stream that audio flows out of, so it is not -- and a filter
    // of `isStream && !isSink` shows the visualiser while hiding the video.
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.isSink)

    // Without a tracker holding them, a PipeWire node's volume and mute stay at
    // whatever they were when first read -- so every node with a slider in the
    // mixer has to be in here, not just the default sink.
    PwObjectTracker {
        objects: root.sinks.concat(root.streams)
    }

    // What to call a node on screen. `nickname` is the short human name
    // ("ORA4 by Kanto"); `description` is the long one; `name` is the raw node
    // id ("alsa_output.usb-..."), which only streams tend to fall back to, and
    // for those it is the binary name, so it is worth capitalising.
    function label(node) {
        if (!node)
            return "";

        if (node.nickname)
            return node.nickname;

        if (node.description)
            return node.description;

        return node.name.charAt(0).toUpperCase() + node.name.slice(1);
    }

    function setSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setVolume(node, value) {
        if (node && node.audio)
            // Capped at 1.0 rather than allowing PipeWire's software boost,
            // which is an easy way to distort the output by leaning on a wheel.
            node.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleMute(node) {
        if (node && node.audio)
            node.audio.muted = !node.audio.muted;
    }
}
