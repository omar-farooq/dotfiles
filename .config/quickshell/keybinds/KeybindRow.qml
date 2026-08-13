// One row of the keybinding cheat sheet: the combination, then what it does.

import QtQuick
import Quickshell
import "root:/theme"
import "root:/components"

Rectangle {
    id: root

    required property var bind
    property bool selected: false

    signal hovered

    implicitHeight: 32
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
        onEntered: root.hovered()
    }

    Row {
        id: inner

        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 12
            rightMargin: 12
        }
        spacing: 12

        // Heights are left at BarText's own, deliberately. Binding them to
        // `parent.height` inside a Row is circular -- a Row takes its height
        // from its children -- and the loop resolves to zero, which renders as
        // a list of empty highlighted rows.

        // Fixed-width key column, so the descriptions line up into a second
        // column instead of stepping raggedly across the panel.
        BarText {
            width: 210
            text: root.bind.keys
            font.family: Theme.monoFont
            font.pixelSize: Theme.fontSize - 1
            elide: Text.ElideRight
        }

        BarText {
            width: parent.width - 234
            text: root.bind.submap !== "" ? `${root.bind.description}   (submap: ${root.bind.submap})` : root.bind.description
            font.weight: Font.Normal
            opacity: 0.85
            elide: Text.ElideRight
        }
    }
}
