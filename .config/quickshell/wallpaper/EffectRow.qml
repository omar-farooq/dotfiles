// One wallpaper effect in the list.

import QtQuick
import Quickshell
import "root:/theme"
import "root:/components"

Rectangle {
    id: root

    required property string name
    property bool current: false
    property bool selected: false

    signal activated
    signal hovered

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

        // See KeybindRow: heights are left at the children's own. Binding them
        // to parent.height inside a Row is circular and resolves to zero.

        // Faded rather than hidden, so the tick occupies its slot on every row
        // and the names stay in one column instead of the active one shifting.
        BarIcon {
            width: 14
            text: Icons.check
            font.pixelSize: Theme.fontSize - 2
            opacity: root.current ? 0.85 : 0
        }

        BarText {
            width: parent.width - 24
            text: root.name
            font.weight: root.current ? Font.DemiBold : Font.Normal
            opacity: root.current ? 1.0 : 0.85
            elide: Text.ElideRight
        }
    }
}
