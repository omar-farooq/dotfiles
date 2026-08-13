// One result in the launcher list.

import QtQuick
import Quickshell
import Quickshell.Widgets
import "root:/theme"
import "root:/components"

Rectangle {
    id: root

    required property var entry
    property bool selected: false

    signal activated
    signal hovered

    implicitHeight: 46
    radius: 10

    // The selected row is the only lit one. Hover feeds the same selection
    // rather than drawing a second highlight, so the keyboard and the mouse
    // never disagree about where you are.
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
            leftMargin: 10
            rightMargin: 10
        }
        spacing: 12

        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: 30
            source: root.entry.icon ? `image://icon/${root.entry.icon}` : ""
            visible: source !== ""
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 42
            spacing: 1

            BarText {
                width: parent.width
                height: implicitHeight
                text: root.entry.name
                elide: Text.ElideRight
            }

            BarText {
                width: parent.width
                height: implicitHeight
                // genericName before comment: "Web Browser" is a more useful
                // second line than a marketing sentence.
                text: root.entry.genericName || root.entry.comment || ""
                visible: text !== ""
                font.weight: Font.Normal
                font.pixelSize: Theme.fontSize - 2
                opacity: 0.6
                elide: Text.ElideRight
            }
        }
    }
}
