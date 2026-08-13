// The rounded chrome every bar module sits in.
//
// waybar spread this across two dozen near-identical CSS blocks -- #clock,
// #network, #pulseaudio, #battery, #backlight and the rest were all "background
// colour, 15px radius, 0.8 opacity, the same padding". One component instead,
// so the bar's shape is a single edit.

import QtQuick
import "root:/theme"

Rectangle {
    id: root

    // Children go into the inner Row. Note the `data: [...]` block further
    // down: once a component aliases its default property, everything declared
    // inside this file would land in that alias too, so the Row and the
    // MouseArea have to be assigned to `data` explicitly to stay out of it.
    default property alias content: layout.data

    property color accent: Theme.surface
    property bool interactive: true
    property int padding: Theme.pillPadding
    property alias spacing: layout.spacing
    readonly property alias hovered: mouse.containsMouse

    signal clicked
    signal rightClicked
    signal middleClicked

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
            enabled: root.interactive
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor

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
        }
    ]
}
