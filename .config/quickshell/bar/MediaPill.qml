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

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "root:/theme"
import "root:/components"

Pill {
    id: root

    // Spotify only, which is what waybar's `--player spotify` meant. Widening
    // this to "whatever is playing" is a one-line change -- but it also means
    // every YouTube tab and every video in a browser takes over the pill, which
    // is presumably why it was pinned to one player to begin with.
    readonly property string preferred: "spotify"

    readonly property var player: {
        const match = p => `${p.dbusName || ""} ${p.identity || ""}`.toLowerCase().includes(root.preferred);
        return Mpris.players.values.find(match) || null;
    }

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

    onClicked: if (root.player && root.player.canTogglePlaying)
        root.player.togglePlaying()

    // Bring the player to the front. waybar had nothing on right click here.
    onRightClicked: if (root.player && root.player.canRaise)
        root.player.raise()

    onWheel: delta => {
        if (!root.player)
            return;

        if (delta > 0) {
            if (root.player.canGoNext)
                root.player.next();
        } else if (root.player.canGoPrevious) {
            root.player.previous();
        }
    }

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
