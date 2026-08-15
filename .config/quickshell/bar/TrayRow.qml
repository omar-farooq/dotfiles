// System tray (StatusNotifierItem).
//
// Minus anything the bar already shows somewhere better. Spotify registers a
// tray icon, and SpotifyPill is a richer version of exactly the same thing --
// same application, same controls, with album art and a seek bar besides -- so
// carrying both put one app at each end of the bar.

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "root:/theme"
import "root:/services"

Row {
    id: root

    spacing: Theme.gap

    readonly property var shown: SystemTray.items.values.filter(item => !root.covered(item))

    // Identified by Media rather than named again here, so the pill and this
    // cannot drift apart about which application is covered -- and only while
    // the pill is actually up. With no pill, the tray icon is the only Spotify
    // on the bar, and hiding it then would remove the app from the bar
    // altogether rather than de-duplicating it. The pill's panel carries this
    // item's menu, so nothing that lived behind the icon is lost.
    function covered(item) {
        return Media.preferred !== null && item === Media.trayItem;
    }

    // Row keeps its spacing even with nothing in it, which would leave a hole
    // between the drawers and the bell on a session with no tray apps -- or one
    // whose only tray app is the covered one.
    visible: root.shown.length > 0

    Repeater {
        model: root.shown

        delegate: Item {
            id: entry

            required property SystemTrayItem modelData

            implicitWidth: 18
            implicitHeight: Theme.pillHeight

            IconImage {
                anchors.centerIn: parent
                source: entry.modelData.icon
                implicitSize: 18
                opacity: mouse.containsMouse ? 1.0 : 0.85

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
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor

                onClicked: event => {
                    if (event.button === Qt.LeftButton) {
                        entry.modelData.activate();
                    } else if (event.button === Qt.RightButton) {
                        entry.showMenu();
                    } else {
                        entry.modelData.secondaryActivate();
                    }
                }
            }

            // Hands the menu back to the owning application to draw, anchored
            // under this icon. Quickshell can render SNI menus itself, but that
            // means restyling every app's menu to match the bar -- a job for
            // the phase that replaces rofi, not this one.
            function showMenu() {
                if (entry.modelData.hasMenu)
                    entry.modelData.display(QsWindow.window, entry.width / 2, entry.height);
            }
        }
    }
}
