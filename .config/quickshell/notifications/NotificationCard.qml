// One notification.

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "root:/theme"
import "root:/services"
import "root:/components"

Rectangle {
    id: root

    required property var notification

    readonly property bool critical: notification.urgency === NotificationUrgency.Critical

    // dunst's width was 300. A little wider earns back the space the icon takes
    // on the left, which dunst counted separately.
    implicitWidth: 340
    implicitHeight: layout.implicitHeight + 24

    radius: 12

    // Critical keeps dunst's red ground. Everything else sits on the wallpaper
    // palette's own background rather than dunst's flat black, so a
    // notification reads as part of the same desktop as the bar.
    color: root.critical ? Qt.rgba(0.56, 0, 0, 0.88) : Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.88)

    border.width: 1
    border.color: root.critical ? Theme.text : Qt.rgba(1, 1, 1, 0.14)

    // ------------------------------------------------------------------
    // Expiry
    //
    // The sender's own timeout wins when it gave one. Zero means "leave it up
    // until dismissed", which is the spec's way of saying the message matters
    // -- dunst overrode that and expired everything after six seconds; this
    // honours it.
    // ------------------------------------------------------------------

    readonly property int lifetime: {
        const asked = root.notification.expireTimeout;
        if (asked === 0)
            return 0;
        return asked > 0 ? asked : Notifications.timeout;
    }

    Timer {
        // Paused while the pointer is on the card, so a notification cannot
        // expire out from under you while you are reading it or reaching for
        // one of its actions.
        running: root.lifetime > 0 && !hover.containsMouse
        interval: root.lifetime
        onTriggered: root.notification.expire()
    }

    MouseArea {
        id: hover

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        // The three dunst mouse bindings, kept as they were.
        onClicked: event => {
            if (event.button === Qt.LeftButton) {
                root.notification.dismiss();
            } else if (event.button === Qt.RightButton) {
                Notifications.dismissAll();
            } else if (root.notification.actions.length > 0) {
                root.notification.actions[0].invoke();
            }
        }
    }

    Row {
        id: layout

        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 12
            rightMargin: 12
        }
        spacing: 10

        // The sender's own image if it supplied one (album art, a photo),
        // otherwise its application icon.
        Item {
            id: iconSlot

            // An icon-less sender gets no gap either -- the text starts where
            // the icon would have been.
            readonly property string source: {
                if (root.notification.image !== "")
                    return root.notification.image;
                if (root.notification.appIcon !== "")
                    return `image://icon/${root.notification.appIcon}`;
                return "";
            }

            width: visible ? 36 : 0
            height: 36
            anchors.verticalCenter: parent.verticalCenter
            visible: iconSlot.source !== ""

            IconImage {
                anchors.fill: parent
                // Guarded: handing IconImage an empty source makes it complain
                // about failing to load an icon at 2x2 on every notification
                // that has neither an image nor an app icon.
                source: iconSlot.source
                visible: iconSlot.visible
            }
        }

        Column {
            width: parent.width - (iconSlot.visible ? 46 : 0)
            spacing: 3

            BarText {
                width: parent.width
                text: root.notification.summary
                height: implicitHeight
                elide: Text.ElideRight
            }

            BarText {
                width: parent.width
                text: root.notification.body
                visible: text !== ""
                height: implicitHeight
                font.weight: Font.Normal

                // dunst ran with `markup = full`, so senders here already
                // assume they can use <b> and <i>. StyledText covers that
                // subset; anything richer degrades to plain text rather than
                // showing raw tags.
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: 6
                elide: Text.ElideRight
                opacity: 0.85
            }

            // Actions, when the sender offered any.
            Row {
                spacing: 6
                visible: root.notification.actions.length > 0
                topPadding: 4

                Repeater {
                    model: root.notification.actions

                    delegate: Rectangle {
                        required property var modelData

                        implicitWidth: actionLabel.implicitWidth + 16
                        implicitHeight: 22
                        radius: height / 2
                        color: Qt.rgba(1, 1, 1, actionHover.containsMouse ? 0.24 : 0.12)

                        BarText {
                            id: actionLabel

                            anchors.centerIn: parent
                            height: parent.height
                            text: modelData.text
                            font.pixelSize: Theme.fontSize - 1
                        }

                        MouseArea {
                            id: actionHover

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.invoke()
                        }
                    }
                }
            }
        }
    }
}
