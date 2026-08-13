// One clipboard entry in the picker list.

import QtQuick
import Quickshell
import "root:/theme"
import "root:/components"

Rectangle {
    id: root

    required property var entry
    property bool selected: false

    signal activated
    signal hovered

    // cliphist stores images and other blobs as a placeholder line. Worth
    // marking, because the preview text for one is unreadable noise.
    readonly property bool binary: /^\s*\[\[\s*binary data/.test(root.entry.preview)

    implicitHeight: 34
    radius: 8

    color: root.selected ? Qt.rgba(Theme.surfaceStrong.r, Theme.surfaceStrong.g, Theme.surfaceStrong.b, 0.85) : "transparent"

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

    Row {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 12
            rightMargin: 12
        }
        spacing: 10

        BarIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: root.binary ? Icons.image : Icons.clipboard
            font.pixelSize: Theme.iconSize - 2
            opacity: 0.5
            width: 16
        }

        BarText {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 26
            height: implicitHeight

            text: root.entry.preview
            font.weight: Font.Normal
            font.family: root.binary ? Theme.textFont : Theme.monoFont

            // Middle elision, matching dunst's -- the ends of a clipboard entry
            // are usually what identifies it, and a long paste that shares a
            // prefix with three others is indistinguishable if truncated.
            elide: Text.ElideMiddle
            opacity: root.binary ? 0.6 : 1.0
        }
    }
}
