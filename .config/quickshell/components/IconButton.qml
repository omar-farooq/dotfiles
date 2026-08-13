// A bare clickable glyph, with no pill behind it.
//
// The power button and the drawer contents use this: a row of small icons reads
// as a group, where giving each one its own pill would read as a row of
// unrelated buttons.

import QtQuick
import "root:/theme"

Item {
    id: root

    property alias icon: label.text
    property color color: Theme.text
    property bool interactive: true

    signal clicked
    signal rightClicked

    implicitWidth: Math.max(18, label.implicitWidth)
    implicitHeight: Theme.pillHeight

    BarIcon {
        id: label

        anchors.centerIn: parent
        color: root.color
        opacity: !root.interactive ? 1.0 : (mouse.containsMouse ? 1.0 : 0.8)

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animation
            }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        enabled: root.interactive
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: event => {
            if (event.button === Qt.LeftButton)
                root.clicked();
            else
                root.rightClicked();
        }
    }
}
