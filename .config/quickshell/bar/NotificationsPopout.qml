// What has been said to you lately.
//
// The overlay shows a notification once and then it is gone forever, which
// makes every message something you have to catch inside six seconds. This is
// the other half: the same messages, kept, in the order they arrived.
//
// Rows are records rather than live notifications -- the objects behind them
// were destroyed when their cards closed (see services/Notifications.qml). So
// there is nothing here to act on: no actions, no reply, and clicking a row
// removes it rather than opening anything. Actions belong on the card, while
// the sender is still listening.

import QtQuick
import Quickshell
import Quickshell.Widgets
import "root:/theme"
import "root:/components"
import "root:/services"

Popout {
    id: root

    readonly property int contentWidth: 340

    // About eight rows. Past that the panel is taller than it is useful and the
    // list scrolls instead -- a notification centre that reaches the bottom of
    // the screen has stopped being a panel and become a window.
    readonly property int maxListHeight: 360

    readonly property int rowHeight: 44

    // Opening the panel is the act of reading it, so the badge clears here
    // rather than on any particular row being looked at.
    onOpenChanged: if (root.open)
        Notifications.markRead()

    // ...and anything that arrives while it is open has been read too: the row
    // appeared under your eyes. Without this the pill would sit there claiming
    // you had missed something you just watched arrive.
    Connections {
        target: Notifications
        enabled: root.open

        function onHistoryChanged() {
            Notifications.markRead();
        }
    }

    Column {
        spacing: 6

        Item {
            width: root.contentWidth
            height: 22

            PanelText {
                anchors.left: parent.left
                height: parent.height
                text: "Notifications"
                font.weight: Font.DemiBold
            }

            TextButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "Clear"
                visible: Notifications.history.length > 0

                onClicked: Notifications.clearHistory()
            }
        }

        PanelText {
            height: root.rowHeight
            text: "Nothing yet today"
            opacity: 0.4
            visible: Notifications.history.length === 0
        }

        ListView {
            width: root.contentWidth
            height: Math.min(root.maxListHeight, contentHeight)
            clip: true
            spacing: 2

            // Rebuilt whenever the array is replaced, which is once per
            // notification -- rare enough that modelling on the array itself
            // costs nothing here, unlike a polled reading.
            model: Notifications.history

            delegate: Item {
                id: row

                required property var modelData

                width: root.contentWidth
                height: root.rowHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: -6
                    anchors.rightMargin: -6
                    radius: 8
                    color: Theme.surface
                    opacity: hover.containsMouse ? 0.35 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.animation
                        }
                    }
                }

                // Critical keeps a trace of the card's red ground: a full red
                // row would shout at you about something that has already
                // happened, but an unmarked one would lose the only thing that
                // distinguished it.
                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2
                    height: parent.height - 12
                    radius: 1
                    color: Theme.danger
                    visible: row.modelData.critical
                }

                IconImage {
                    id: icon

                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22
                    // Guarded like the card's: an empty source makes IconImage
                    // complain about a failed 2x2 icon on every senderless row.
                    source: row.modelData.icon
                    visible: row.modelData.icon !== ""
                }

                PanelText {
                    id: summary

                    anchors.left: icon.visible ? icon.right : parent.left
                    anchors.leftMargin: icon.visible ? 10 : 8
                    anchors.right: time.left
                    anchors.rightMargin: 8
                    anchors.top: parent.top
                    anchors.topMargin: 5
                    height: 18
                    text: row.modelData.summary
                    elide: Text.ElideRight
                    font.weight: Font.DemiBold
                }

                PanelText {
                    anchors.left: summary.left
                    anchors.right: time.left
                    anchors.rightMargin: 8
                    anchors.top: summary.bottom
                    height: 16
                    // The sender's name when there was no body. A row with a
                    // blank second line looks like something failed to load;
                    // "Spotify" at least says who was talking.
                    text: row.modelData.body || row.modelData.appName
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSize - 2
                    font.weight: Font.Normal
                    opacity: 0.6
                }

                PanelText {
                    id: time

                    anchors.right: parent.right
                    anchors.rightMargin: 2
                    anchors.top: parent.top
                    anchors.topMargin: 5
                    height: 18
                    text: Qt.formatDateTime(new Date(row.modelData.time), "HH:mm")
                    font.pixelSize: Theme.fontSize - 3
                    opacity: 0.45
                }

                MouseArea {
                    id: hover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: Notifications.forget(row.modelData.key)
                }
            }
        }
    }

    // A small labelled button. The card's action buttons are the same shape and
    // came first; this is not shared with them yet because they carry a
    // notification action and this carries a signal, and merging those would
    // mean one component with two unrelated ways of being used.
    component TextButton: Rectangle {
        id: button

        property alias text: label.text

        signal clicked

        implicitWidth: label.implicitWidth + 16
        implicitHeight: 20
        radius: height / 2
        color: Qt.rgba(1, 1, 1, mouse.containsMouse ? 0.24 : 0.1)

        Behavior on color {
            ColorAnimation {
                duration: Theme.animation
            }
        }

        PanelText {
            id: label

            anchors.centerIn: parent
            font.pixelSize: Theme.fontSize - 3
            opacity: 0.8
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: button.clicked()
        }
    }
}
