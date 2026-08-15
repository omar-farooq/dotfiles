// Now playing, over MPRIS.
//
// Replaces waybar's custom/quicklink7, which ran mediaplayer.py: a permanent
// Python process using playerctl's GLib bindings to print a line of JSON every
// time a track changed. Quickshell speaks MPRIS on D-Bus itself, so that
// process, its dependency on python-gobject and playerctl, and the JSON round
// trip in between all go away.
//
// Controls: left opens the player panel, right toggles play/pause, middle
// raises the player, wheel up is next and wheel down is previous.
//
// The wheel is waybar's. The buttons are not: waybar's click-to-pause moved to
// the right so that left-click could mean what it means on every other pill in
// this bar -- open the panel. Consistency across the bar beat consistency with
// the module this replaced, since the panel is now the thing you reach for
// most and pause has a dedicated key on the keyboard anyway.
//
// Player selection and the transport actions live in the Media service, not
// here, because the XF86Audio* keybinds call the same functions over IPC. The
// pill is just the visible end of it.

import QtQuick
import Quickshell
import Quickshell.Widgets
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
    onClicked: player.toggle()

    onRightClicked: Media.playpause()

    // Bring the player to the front. waybar had nothing on this one.
    onMiddleClicked: Media.raise()

    onWheel: delta => delta > 0 ? Media.next() : Media.previous()

    // Spotify's mark. This used to be the tray icon's job, and the tray row now
    // filters that icon out -- without this the bar would carry album art and a
    // track name with nothing saying which application they belong to.
    BarIcon {
        text: Icons.spotify
        opacity: 0.8
    }

    // The album art beside it. MPRIS has been handing this over all along --
    // waybar's module was a line of text and had nowhere to put a picture. It
    // is a small square, but it is the cover you have been looking at in the
    // player itself, so it names the track faster than reading the artist does.
    //
    // Absent entirely until the art has downloaded, and for a track that has
    // none: the art is on Spotify's CDN rather than on disk, so there is always
    // a moment before it arrives and an offline case where it never does. The
    // glyph already identifies the app, so a placeholder square would add
    // nothing but a flicker between tracks.
    ClippingRectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 18
        height: 18
        radius: 4
        color: "transparent"
        visible: art.status === Image.Ready

        Image {
            id: art

            anchors.fill: parent
            source: root.player ? root.player.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
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

    SpotifyPopout {
        id: player

        anchorItem: root
    }
}
