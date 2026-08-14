// Now playing, over MPRIS.
//
// Replaces waybar's custom/quicklink7, which ran mediaplayer.py: a permanent
// Python process using playerctl's GLib bindings to print a line of JSON every
// time a track changed. Quickshell speaks MPRIS on D-Bus itself, so that
// process, its dependency on python-gobject and playerctl, and the JSON round
// trip in between all go away.
//
// Controls match the old module exactly: click toggles play/pause, wheel up is
// next, wheel down is previous.
//
// Player selection and the transport actions live in the Media service, not
// here, because the XF86Audio* keybinds call the same functions over IPC. The
// pill is just the visible end of it.

import QtQuick
import Quickshell
import "root:/theme"
import "root:/components"
import "root:/services"

Pill {
    id: root

    // Spotify only -- see Media.preferred for why the pill is pinned to one
    // player while the keys are allowed to fall back to any.
    readonly property var player: Media.preferred

    // No player, no pill -- Spotify not running should leave no trace on the
    // bar, the way an empty window title does.
    visible: root.player !== null

    readonly property string label: {
        if (!root.player)
            return "";

        const title = root.player.trackTitle || "";
        const artist = root.player.trackArtist || "";
        return title && artist ? `${artist} — ${title}` : (title || artist || "Spotify");
    }

    // Straight through to the service, which is also what the media keys hit.
    // The pill only exists when Spotify is running, and Media.active prefers
    // Spotify whenever it is running, so these always land on the player named
    // in the label -- there is no case where the pill drives something else.
    onClicked: Media.playpause()

    // Bring the player to the front. waybar had nothing on right click here.
    onRightClicked: Media.raise()

    onWheel: delta => delta > 0 ? Media.next() : Media.previous()

    BarIcon {
        text: Icons.spotify
    }

    BarText {
        text: root.label
        font.weight: Font.Normal
        elide: Text.ElideRight

        // Track names run long, and this sits on the left where it would
        // otherwise push the window title along.
        width: Math.min(implicitWidth, 260)

        // Paused fades rather than swapping in a play glyph: the pill already
        // says what is loaded, and the only question left is whether it is
        // running. waybar showed a static mark and answered neither.
        opacity: root.player && root.player.isPlaying ? 1.0 : 0.55

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animation
            }
        }
    }
}
