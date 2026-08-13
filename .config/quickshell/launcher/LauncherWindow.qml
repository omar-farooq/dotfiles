// The launcher surface.

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import "root:/theme"
import "root:/services"
import "root:/components"

PanelWindow {
    id: root

    property int selected: 0

    visible: Launcher.open

    // Overlay layer with an exclusive keyboard grab. Exclusive matters: without
    // it Hyprland keeps first refusal on keystrokes, so typing an app name
    // would fire whatever keybinds those letters are bound to.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Launcher.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-launcher"

    // Opens on whichever screen has focus, as rofi did.
    screen: {
        const mon = Hyprland.focusedMonitor;
        return (mon && Quickshell.screens.find(s => s.name === mon.name)) || Quickshell.screens[0];
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Covers the screen to catch clicks and dim the desktop, but must not
    // reserve any of it.
    exclusiveZone: 0
    color: "transparent"

    onVisibleChanged: {
        if (root.visible) {
            root.selected = 0;
            input.forceActiveFocus();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.3
    }

    // Click anywhere off the panel to dismiss. Declared before the panel so the
    // panel sits above it and keeps its own clicks.
    MouseArea {
        anchors.fill: parent
        onClicked: Launcher.hide()
    }

    Rectangle {
        id: panel

        anchors.horizontalCenter: parent.horizontalCenter

        // Not vertically centred: a list that grows downward from a fixed point
        // is easier to aim at than one whose rows move every time the result
        // count changes.
        y: Math.round(parent.height * 0.18)

        width: 620
        height: Math.min(460, searchRow.height + list.contentHeight + 24)
        radius: 14

        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.96)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)

        // Swallows clicks so they do not reach the dismiss area behind.
        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: searchRow

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 12
            }
            height: 34

            BarIcon {
                id: prompt

                anchors.verticalCenter: parent.verticalCenter
                text: Icons.search
                opacity: 0.6
            }

            TextInput {
                id: input

                anchors {
                    left: prompt.right
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 10
                }

                // Plain TextInput rather than a Controls TextField: Controls
                // brings a style that would have to be overridden to nothing
                // anyway, and this is one line of text.
                color: Theme.text
                font.family: Theme.textFont
                font.pixelSize: 16
                selectionColor: Theme.surfaceStrong
                selectedTextColor: Theme.text
                clip: true

                onTextChanged: {
                    Launcher.query = text;
                    // Any new keystroke re-aims at the top result, which is
                    // where the thing you are typing towards ends up.
                    root.selected = 0;
                }

                // Cleared on close by the service; mirror that here so the
                // field itself empties too.
                Connections {
                    target: Launcher

                    function onOpenChanged() {
                        if (!Launcher.open)
                            input.text = "";
                    }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        Launcher.hide();
                    } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_J && event.modifiers & Qt.ControlModifier)) {
                        root.selected = Math.min(root.selected + 1, Launcher.results.length - 1);
                    } else if (event.key === Qt.Key_Up || (event.key === Qt.Key_K && event.modifiers & Qt.ControlModifier)) {
                        root.selected = Math.max(root.selected - 1, 0);
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.launch(Launcher.results[root.selected]);
                    } else {
                        return;   // not ours: let it reach the text field
                    }

                    event.accepted = true;
                }

                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    visible: input.text === ""
                    text: "Search applications"
                    color: Theme.text
                    opacity: 0.4
                    font: input.font
                }
            }
        }

        ListView {
            id: list

            anchors {
                top: searchRow.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                topMargin: 6
                bottomMargin: 12
            }

            clip: true
            model: Launcher.results
            currentIndex: root.selected

            // Keeps the keyboard selection on screen when it walks past the
            // bottom of the visible rows.
            highlightMoveDuration: 120
            preferredHighlightBegin: 40
            preferredHighlightEnd: height - 40
            highlightRangeMode: ListView.ApplyRange

            delegate: AppRow {
                required property var modelData
                required property int index

                entry: modelData
                width: list.width
                selected: index === root.selected

                onActivated: root.launch(modelData)
                onHovered: root.selected = index
            }
        }
    }

    function launch(entry) {
        if (!entry)
            return;

        Launcher.hide();
        entry.execute();
    }
}
