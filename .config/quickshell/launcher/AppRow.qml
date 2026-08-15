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
    property bool favourite: false

    signal activated
    signal hovered
    signal togglePin

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
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onEntered: root.hovered()

        onClicked: event => {
            if (event.button === Qt.RightButton)
                root.togglePin();
            else
                root.activated();
        }
    }

    // Pinned marker, at the trailing edge rather than in front of the icon: a
    // star column would be blank on nearly every row and indent all fifty
    // applications to make room for the four that are pinned.
    BarIcon {
        id: pin

        anchors {
            right: parent.right
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }

        text: Icons.star
        visible: root.favourite
        opacity: 0.75
        font.pixelSize: Theme.iconSize - 3
    }

    Row {
        anchors {
            left: parent.left
            right: root.favourite ? pin.left : parent.right
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
