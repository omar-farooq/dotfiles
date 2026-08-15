// One wallpaper in the grid: the picture, its filename, and a tick if it is
// the one currently on screen.

import QtQuick
import Quickshell.Widgets
import "root:/theme"
import "root:/services"
import "root:/components"

Item {
    id: root

    required property string path
    property bool current: false
    property bool selected: false

    // Passed in rather than read here: the `Screen` attached property is not
    // available on a layer-shell surface, and an image decoded at the logical
    // size is drawn at half resolution on DP-3, which runs at a ratio of 2.
    property real dpr: 1

    // Set by the window, which needs the same figure to size the grid's cells.
    // A height measured from the caption's own contents instead would be a
    // binding loop -- cell height would depend on the tile, and the tile's
    // height on the cell.
    property int captionHeight: 26

    signal activated
    signal hovered

    Rectangle {
        id: frame

        anchors.fill: parent
        anchors.margins: 5
        radius: 10

        color: root.selected ? Qt.rgba(Theme.surfaceStrong.r, Theme.surfaceStrong.g, Theme.surfaceStrong.b, 0.85) : "transparent"

        // The ring is the aim, and it is drawn on the frame rather than the
        // picture so it reads at a glance against a bright wallpaper as well as
        // a dark one.
        border.width: root.selected ? 2 : 1
        border.color: root.selected ? Qt.rgba(1, 1, 1, 0.75) : Theme.panelBorder

        Behavior on color {
            ColorAnimation {
                duration: Theme.animation
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: root.activated()
            onEntered: root.hovered()
        }

        ClippingRectangle {
            id: picture

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                bottom: caption.top
                margins: 5
                bottomMargin: 0
            }

            radius: 6

            // Shows through until the image arrives, so a grid mid-load is a
            // set of empty frames rather than holes in the panel.
            color: Qt.rgba(1, 1, 1, 0.06)

            // The cache is built in the background and may not have caught up
            // -- on a machine seeing this folder for the first time, or one
            // where imagemagick is missing entirely. Falling back to the
            // original keeps the grid correct in both cases; it is only heavier.
            // See Wallpaper.qml for what that costs.
            //
            // A cold cache therefore puts a "Cannot open ..." warning in
            // `qs log` per tile. That is this working, not this failing.
            property bool thumbMissing: false

            readonly property string thumb: Wallpaper.thumbFor(root.path)

            Image {
                anchors.fill: parent

                source: `file://${picture.thumbMissing ? root.path : picture.thumb}`
                fillMode: Image.PreserveAspectCrop
                asynchronous: true

                // Decoded at the size drawn rather than the size stored. The
                // thumbnails are already small; this is what keeps the fallback
                // path from holding a hundred full-resolution originals.
                sourceSize.width: Math.round(width * root.dpr)

                onStatusChanged: {
                    if (status === Image.Error && !picture.thumbMissing)
                        picture.thumbMissing = true;
                }

                // A thumbnailing pass has finished, so anything that fell back
                // can try the cache again.
                Connections {
                    target: Wallpaper

                    function onThumbEpochChanged() {
                        picture.thumbMissing = false;
                    }
                }
            }
        }

        Item {
            id: caption

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 9
                rightMargin: 9
            }

            height: root.captionHeight

            // Faded rather than hidden, so the name starts at the same x on
            // every tile instead of shifting sideways on the one that is set.
            BarIcon {
                id: tick

                anchors.verticalCenter: parent.verticalCenter
                width: 13
                height: parent.height
                text: Icons.check
                font.pixelSize: Theme.fontSize - 3
                opacity: root.current ? 0.9 : 0
            }

            BarText {
                anchors {
                    left: tick.right
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 6
                }

                height: parent.height

                // The extension carries no information here -- every file in the
                // folder is a picture, and dropping it buys ten characters of
                // name before the elide bites.
                text: {
                    const name = Wallpaper.basename(root.path);
                    return name.replace(/\.[^.]+$/, "");
                }

                font.pixelSize: Theme.fontSize - 2
                font.weight: root.current ? Font.DemiBold : Font.Normal
                opacity: root.current ? 1.0 : 0.8
                elide: Text.ElideRight
            }
        }
    }
}
