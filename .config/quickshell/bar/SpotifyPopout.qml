// The player, under the media pill.
//
// The pill is one line of text because waybar's module could only ever be one
// line of text -- MPRIS was handing over album art, a track length and a
// position the whole time, and mediaplayer.py threw all of it away because
// there was nowhere to put it. This is that discarded half.
//
// Everything acts through services/Media.qml rather than on a player found
// here, so the panel, the pill above it and the XF86Audio keys are all driving
// the same object. The pill only exists while Spotify is running and Media
// prefers Spotify whenever it is running, so the player under this panel is
// always the one named in the pill.

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "root:/theme"
import "root:/components"
import "root:/services"

Popout {
    id: root

    // Lines up with the pill's left edge: this is the one popout hanging off
    // the bar's left-hand section. See Popout.alignLeft.
    alignLeft: true

    readonly property int contentWidth: 320
    readonly property int artSize: 84

    // The player this panel drives. Defaults to the one the pill above it
    // shows, and is a plain property rather than a binding of its own so it can
    // be pointed elsewhere -- at a stand-in while working on the layout, or at
    // a chosen player if this ever grows a way to pick between them.
    property var player: Media.preferred

    readonly property bool seekable: root.player && root.player.canSeek && root.player.lengthSupported && root.player.length > 0

    // MPRIS pushes a position only when something seeks, so a progress bar that
    // moves has to ask. Once a second is enough for a bar this wide (a pixel is
    // about four seconds of a normal track) and it only runs while the panel is
    // open and the player is playing -- polling a paused player, or one nobody
    // is looking at, would be a wakeup a second for nothing.
    property real position: 0

    Timer {
        interval: 1000
        repeat: true
        running: root.open && root.player !== null && root.player.isPlaying
        triggeredOnStart: true
        onTriggered: root.position = root.player ? root.player.position : 0
    }

    // A seek or a track change lands immediately rather than at the next tick,
    // so the handle does not spring back for a moment after being dragged.
    onOpenChanged: if (root.open && root.player)
        root.position = root.player.position

    function refresh() {
        if (root.player)
            root.position = root.player.position;
    }

    // mm:ss, and h:mm:ss only when there is an hour to show -- a podcast should
    // not force every three-minute track to display a leading zero hour.
    function clock(seconds) {
        if (!(seconds >= 0))
            return "0:00";

        const whole = Math.floor(seconds);
        const s = whole % 60;
        const m = Math.floor(whole / 60) % 60;
        const h = Math.floor(whole / 3600);

        const pad = n => (n < 10 ? `0${n}` : `${n}`);
        return h > 0 ? `${h}:${pad(m)}:${pad(s)}` : `${m}:${pad(s)}`;
    }

    Column {
        spacing: 10

        // -------------------------------------------------------------
        // Art, and everything written about the track.
        // -------------------------------------------------------------

        Row {
            spacing: 12

            // Rounded corners need Quickshell's ClippingRectangle: a plain
            // Rectangle with `clip: true` clips to its bounding box, so the
            // artwork's square corners would sit proud of the rounded ones.
            ClippingRectangle {
                width: root.artSize
                height: root.artSize
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.06)

                Image {
                    id: art

                    anchors.fill: parent
                    source: root.player ? root.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true

                    // Spotify's art is an https URL on their CDN, not a file on
                    // disk, so this is a download that can be slow or simply not
                    // happen. Anything short of a loaded image falls back to the
                    // glyph rather than leaving a hole where the art goes.
                    visible: art.status === Image.Ready
                }

                BarIcon {
                    anchors.centerIn: parent
                    text: Icons.spotify
                    font.pixelSize: 28
                    opacity: 0.35
                    visible: !art.visible
                }
            }

            Item {
                width: root.contentWidth - root.artSize - 12
                height: root.artSize

                // The player's own tray menu, drawn by the player, hung under
                // this button. That menu is where minimise-to-tray and Quit
                // live -- Spotify's indicator implements no Activate handler,
                // so they exist nowhere else -- and filtering its icon out of
                // the tray row would have taken both away with it. This is the
                // icon's right click, rehomed.
                IconButton {
                    id: menuButton

                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: -4
                    icon: Icons.more
                    visible: Media.trayItem !== null && Media.trayItem.hasMenu

                    // display() wants coordinates in the window's frame, not
                    // this item's, so they are mapped rather than passed raw.
                    onClicked: {
                        const at = menuButton.mapToItem(null, menuButton.width / 2, menuButton.height);
                        Media.trayItem.display(QsWindow.window, at.x, at.y);
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: menuButton.visible ? menuButton.left : parent.right
                    anchors.rightMargin: 6
                    anchors.top: parent.top
                    spacing: 4

                    PanelText {
                        width: parent.width
                        text: root.player ? (root.player.trackTitle || "Nothing playing") : "Nothing playing"
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    PanelText {
                        width: parent.width
                        text: root.player ? root.player.trackArtist : ""
                        visible: text !== ""
                        elide: Text.ElideRight
                        font.pixelSize: Theme.fontSize - 1
                        opacity: 0.75
                    }

                    PanelText {
                        width: parent.width
                        text: root.player ? root.player.trackAlbum : ""
                        visible: text !== ""
                        elide: Text.ElideRight
                        font.pixelSize: Theme.fontSize - 2
                        opacity: 0.45
                    }
                }
            }
        }

        // -------------------------------------------------------------
        // Position. The slider is the same one the mixer uses, so a drag
        // behaves the way a volume drag does.
        // -------------------------------------------------------------

        Item {
            width: root.contentWidth
            height: 18
            visible: root.seekable

            Slider {
                id: scrubber

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                value: root.player && root.player.length > 0 ? root.position / root.player.length : 0

                onMoved: value => {
                    // Set locally as well as on the player: the readout should
                    // follow the handle as it is dragged rather than waiting
                    // for the next poll to catch up with it.
                    root.position = value * root.player.length;
                    Media.seek(root.position);
                }
            }
        }

        Item {
            width: root.contentWidth
            height: 14
            visible: root.seekable

            PanelText {
                anchors.left: parent.left
                text: root.clock(root.position)
                font.pixelSize: Theme.fontSize - 3
                opacity: 0.5
            }

            PanelText {
                anchors.right: parent.right
                text: root.clock(root.player ? root.player.length : 0)
                font.pixelSize: Theme.fontSize - 3
                opacity: 0.5
            }
        }

        // -------------------------------------------------------------
        // Transport, with the two playback modes either side of it.
        // -------------------------------------------------------------

        Item {
            width: root.contentWidth
            height: 30

            // Shuffle and repeat sit out at the edges rather than in the
            // transport group: they change what happens next, while the three
            // in the middle act now, and mixing them into one row of five
            // makes the play button harder to find in a hurry.
            IconButton {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons.shuffle
                interactive: root.player !== null && root.player.shuffleSupported
                color: root.player && root.player.shuffle ? Theme.surfaceStrong : Theme.text
                opacity: root.player && root.player.shuffle ? 1.0 : 0.45

                onClicked: Media.toggleShuffle()
            }

            Row {
                anchors.centerIn: parent
                spacing: 14

                IconButton {
                    icon: Icons.stepBack
                    interactive: root.player !== null && root.player.canGoPrevious

                    onClicked: {
                        Media.previous();
                        root.refresh();
                    }
                }

                IconButton {
                    icon: root.player && root.player.isPlaying ? Icons.pause : Icons.play
                    interactive: root.player !== null && root.player.canTogglePlaying

                    onClicked: Media.playpause()
                }

                IconButton {
                    icon: Icons.stepForward
                    interactive: root.player !== null && root.player.canGoNext

                    onClicked: {
                        Media.next();
                        root.refresh();
                    }
                }
            }

            IconButton {
                id: loop

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons.repeat
                interactive: root.player !== null && root.player.loopSupported
                color: root.player && root.player.loopState !== MprisLoopState.None ? Theme.surfaceStrong : Theme.text
                opacity: root.player && root.player.loopState !== MprisLoopState.None ? 1.0 : 0.45

                onClicked: Media.cycleLoop()

                // Font Awesome's free set has no repeat-one glyph, so the one
                // track case is the same glyph with a 1 tucked against it --
                // which is how the icon that does exist elsewhere draws it.
                PanelText {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 3
                    text: "1"
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    color: Theme.surfaceStrong
                    visible: root.player && root.player.loopState === MprisLoopState.Track
                }
            }
        }
    }
}
