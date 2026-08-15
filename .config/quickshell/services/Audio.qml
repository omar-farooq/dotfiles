pragma Singleton

// Everything the bar knows about PipeWire, in one place.
//
// The volume pill used to talk to Pipewire directly, which was fine while the
// only question was "how loud is the default sink". The mixer asks three more
// -- which outputs exist, which one is default, and what is playing -- and both
// it and the pill have to agree on the answers, so they come from here.
//
// Device labels are assembled from `nickname`/`description`/`name`; streams
// prefer their `media.name` property, which is the tab or track title.
//
// Note that `PwNode.properties` only fills in once something holds the node --
// the same `PwObjectTracker` requirement as volume and mute. Read through a
// service that tracks its nodes and the map is complete; read it from a bare
// probe with no tracker and every node looks like it has no properties at all,
// which is a very convincing way to conclude the data does not exist.

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
    //
    // Sorted by name, because the order PipeWire hands them over is its own and
    // changes between reads -- a chooser whose rows swap places between one
    // opening and the next is a chooser you have to read every time instead of
    // aiming at from memory. Streams are deliberately left in PipeWire's order,
    // which is the order they started: sorting those by title would have rows
    // jumping about as a tab renames itself.
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream).sort((a, b) => root.label(a).localeCompare(root.label(b)))

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

    // Placeholders a client uses before it has anything to say. Firefox opens a
    // stream as "AudioStream" and only names it once the page settles, so these
    // have to fall through to the application name rather than be shown.
    readonly property var placeholderNames: ["AudioStream", "Playback", "audio-stream", "playStream"]

    // What to call a *stream*. `media.name` is the tab or track title -- the
    // only thing that separates two Firefox windows, which are otherwise both
    // just "Firefox" -- and it updates live as the title changes.
    function streamLabel(node) {
        if (!node)
            return "";

        const media = node.properties ? node.properties["media.name"] : "";

        if (media && root.placeholderNames.indexOf(media) === -1)
            return media;

        return root.label(node);
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

    // -----------------------------------------------------------------
    // Taming loud starters
    //
    // Firefox opens every stream at whatever its page's volume slider says, and
    // a YouTube tab with no stored site data says 100%. Omar clears Firefox's
    // site storage on exit by design, so YouTube forgets its level on every
    // launch and the first thing a video does is shout.
    //
    // This cannot be fixed in the sound server. WirePlumber's
    // `state.default-volume` and its saved per-application level both land at
    // stream creation and are then overwritten by Firefox a beat later --
    // measured: the stream is born at 1.0 and its volume tracks the page slider
    // exactly (page 17 -> channelVolume 0.17). Anything the server sets loses.
    //
    // So the level is set here instead, once, just after the stream shows up --
    // late enough to be after Firefox. Moving the page's own slider afterwards
    // still wins, which is correct: that is the user asking.
    // -----------------------------------------------------------------

    // Matched against the node's name, lowercased.
    readonly property var tameApps: ["firefox"]

    // In the same perceptual scale as everything else here -- `PwNodeAudio`'s
    // volume is the cube root of PipeWire's raw `channelVolumes`, so 0.5 here
    // lands as 0.125 linear, and the mixer's "50%" means this too. That is the
    // scale a volume control should be in, and it is why WirePlumber's
    // `state.default-volume`, which takes the *linear* value, would have needed
    // 0.125 to mean the same thing.
    //
    // 0.5 sits just under the level Omar picks by hand: YouTube's page slider at
    // 17 is 0.17 linear, which is 0.55 here.
    readonly property real tameVolume: 0.5

    // Streams already dealt with, by node id. Rebuilt from the live list on
    // every pass rather than grown forever, because PipeWire reuses node ids: an
    // id remembered after its stream is gone would make the next stream to claim
    // that id look like one already handled, and it would come up loud.
    property var tamed: ({})

    function shouldTame(node) {
        return root.tameApps.indexOf((node.name || "").toLowerCase()) !== -1;
    }

    function tameNewStreams() {
        const next = {};

        for (const node of root.streams) {
            const seen = root.tamed[node.id] === true;
            next[node.id] = true;

            if (!seen && node.audio && root.shouldTame(node))
                root.setVolume(node, root.tameVolume);
        }

        root.tamed = next;
    }

    onStreamsChanged: settle.restart()

    Timer {
        id: settle

        // Not immediate: the node can reach this model before its audio is
        // bound, and before Firefox has finished asserting its own volume.
        // Setting it too early is setting it into the void.
        interval: 400
        repeat: false

        onTriggered: root.tameNewStreams()
    }
}
