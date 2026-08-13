// Output volume, straight from PipeWire.
//
// waybar went through its pulseaudio module, which talks to PipeWire's Pulse
// shim; this talks to PipeWire itself, so the volume it shows is the one the
// server actually holds.

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "root:/theme"
import "root:/components"

Pill {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property int volume: audio ? Math.round(audio.volume * 100) : 0
    readonly property bool muted: audio ? audio.muted : false

    readonly property string icon: {
        if (root.muted)
            return Icons.volumeMuted;

        // Thirds, matching waybar's three-icon default array.
        const levels = Icons.volumeLevels;
        const index = Math.min(levels.length - 1, Math.floor(root.volume / (100 / levels.length)));
        return levels[Math.max(0, index)];
    }

    onClicked: Quickshell.execDetached(["pavucontrol"])
    onRightClicked: if (root.audio)
        root.audio.muted = !root.audio.muted

    // PipeWire objects are lazily bound -- without a tracker holding the sink,
    // its volume and mute properties never update and the pill freezes at
    // whatever it read first.
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    BarIcon {
        text: root.icon
    }

    BarText {
        text: root.muted ? "muted" : `${root.volume}%`
    }

    // Scroll to adjust -- new; waybar had scroll-step commented out. Capped at
    // 1.0 rather than letting PipeWire's software boost past 100%, which is an
    // easy way to distort the output by leaning on the wheel.
    onWheel: delta => {
        if (!root.audio)
            return;

        root.audio.volume = Math.max(0, Math.min(1, root.audio.volume + (delta > 0 ? 0.02 : -0.02)));
    }
}
