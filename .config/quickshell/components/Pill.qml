// The rounded chrome every bar module sits in.
//
// waybar spread this across two dozen near-identical CSS blocks -- #clock,
// #network, #pulseaudio, #battery, #backlight and the rest were all "background
// colour, 15px radius, 0.8 opacity, the same padding". One component instead,
// so the bar's shape is a single edit.
//
// Input note: this uses MouseArea rather than Qt's newer pointer handlers
// (TapHandler / WheelHandler / HoverHandler) throughout, and so does the rest
// of the bar. Pointer handlers do not receive events on these layer-shell
// surfaces -- a WheelHandler placed here logged nothing across dozens of
// scrolls while a MouseArea in the same position caught every one. Clicks
// looked fine only because they were already going through a MouseArea.

import QtQuick
import "root:/theme"

Rectangle {
    id: root

    // Children go into the inner Row. Note the `data: [...]` block further
    // down: once a component aliases its default property, everything declared
    // inside this file would land in that alias too, so the internals have to
    // be assigned to `data` explicitly to stay out of it.
    default property alias content: layout.data

    // Anything that must sit above the content and cover the whole pill. Drawer
    // uses it to sense hover without the pointer crossing a child button
    // stealing the hover and collapsing the drawer mid-reach.
    property alias overlay: overlaySlot.data

    property color accent: Theme.surface
    property bool interactive: true
    property int padding: Theme.pillPadding
    property alias spacing: layout.spacing
    readonly property alias hovered: mouse.containsMouse

    signal clicked
    signal rightClicked
    signal middleClicked

    // Positive delta is a scroll up. Emitted here rather than handled in each
    // module so the whole pill responds, padding and rounded ends included.
    signal wheel(int delta)

    implicitWidth: layout.implicitWidth + padding * 2
    implicitHeight: Theme.pillHeight
    radius: height / 2

    // Hovering lifts the pill to full opacity rather than changing its colour.
    // Against a wallpaper-derived palette any fixed highlight colour clashes
    // with some wallpapers; opacity never does.
    color: Qt.rgba(accent.r, accent.g, accent.b, interactive && hovered ? 1.0 : Theme.pillOpacity)

    Behavior on color {
        ColorAnimation {
            duration: Theme.animation
        }
    }

    data: [
        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true

            // Always enabled, because this is what carries hover and the wheel
            // as well as clicks. `interactive` only decides whether a click
            // means anything -- a non-interactive pill still scrolls.
            acceptedButtons: root.interactive ? (Qt.LeftButton | Qt.RightButton | Qt.MiddleButton) : Qt.NoButton
            cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor

            onWheel: event => root.wheel(event.angleDelta.y)

            onClicked: event => {
                if (event.button === Qt.LeftButton)
                    root.clicked();
                else if (event.button === Qt.RightButton)
                    root.rightClicked();
                else if (event.button === Qt.MiddleButton)
                    root.middleClicked();
            }
        },
        Row {
            id: layout

            anchors.centerIn: parent
            spacing: 6
        },
        Item {
            id: overlaySlot

            anchors.fill: parent
        }
    ]
}
