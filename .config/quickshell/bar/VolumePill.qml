// Output volume, straight from PipeWire.
//
// waybar went through its pulseaudio module, which talks to PipeWire's Pulse
// shim; this talks to PipeWire itself, so the volume it shows is the one the
// server actually holds. The readings now come via services/Audio.qml, so the
// pill and the mixer below it cannot disagree about which sink is "the" sink.

import QtQuick
import Quickshell
import "root:/theme"
import "root:/components"
import "root:/services"

Pill {
    id: root

    onClicked: mixer.open = !mixer.open
    onRightClicked: Audio.toggleMute(Audio.sink)

    // pavucontrol, which used to be the left click, kept as an escape hatch for
    // the routing and per-device settings the mixer does not try to cover.
    onMiddleClicked: Quickshell.execDetached(["pavucontrol"])

    BarIcon {
        text: Icons.forVolume(Audio.volume, Audio.muted)
    }

    BarText {
        text: Audio.muted ? "muted" : `${Audio.volume}%`
    }

    // Scroll to adjust -- new; waybar had scroll-step commented out.
    onWheel: delta => Audio.setVolume(Audio.sink, (Audio.audio ? Audio.audio.volume : 0) + (delta > 0 ? 0.02 : -0.02))

    VolumePopout {
        id: mixer

        anchorItem: root
    }
}
