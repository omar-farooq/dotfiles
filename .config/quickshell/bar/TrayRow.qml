// System tray (StatusNotifierItem).

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "root:/theme"

Row {
    id: root

    spacing: Theme.gap
    // Row keeps its spacing even with nothing in it, which would leave a hole
    // between the drawers and the power button on a session with no tray apps.
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items

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
