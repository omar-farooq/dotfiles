// A search-and-choose overlay: dimmed screen, centred panel, one text field,
// one keyboard-driven list.
//
// Both the app launcher and the clipboard picker are this with a different
// model and a different delegate, which is why it lives here rather than being
// written twice and then drifting apart.

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "root:/theme"

PanelWindow {
    id: root

    property bool open: false
    property string placeholder: ""
    property var model: []
    property Component delegate: null

    // A line of hint text under the list. Empty hides it.
    property string footer: ""

    property int panelWidth: 620
    property int maxHeight: 460

    readonly property alias query: input.text
    readonly property alias selected: list.currentIndex

    // Called for keys the picker does not claim itself, before the text field
    // sees them. Return true to swallow the key. This is how the clipboard
    // picker gets Delete without the text field treating it as an edit.
    property var keyHandler: null

    signal accepted(int index)
    signal dismissed

    visible: root.open

    // Overlay layer with an exclusive keyboard grab. Exclusive matters: without
    // it Hyprland keeps first refusal on keystrokes, so typing would fire
    // whatever binds those letters have.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-picker"

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

    // Covers the screen to catch stray clicks and dim the desktop, but must
    // never reserve any of it.
    exclusiveZone: 0
    color: "transparent"

    onVisibleChanged: {
        if (root.visible) {
            input.text = "";
            list.currentIndex = 0;
            input.forceActiveFocus();
        }
    }

    function clampSelection() {
        const count = root.model ? root.model.length : 0;
        list.currentIndex = Math.max(0, Math.min(list.currentIndex, count - 1));
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.3
    }

    // Click off the panel to dismiss. Declared before the panel so the panel
    // sits above it and keeps its own clicks.
    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissed()
    }

    Rectangle {
        id: panel

        anchors.horizontalCenter: parent.horizontalCenter

        // Not vertically centred: a list growing downward from a fixed point is
        // easier to aim at than one whose rows shift every time the result
        // count changes.
        y: Math.round(parent.height * 0.18)

        width: root.panelWidth
        height: Math.min(root.maxHeight, searchRow.height + list.contentHeight + (footerLabel.visible ? footerLabel.height + 6 : 0) + 30)
        radius: Theme.panelRadius

        color: Theme.panel
        border.width: 1
        border.color: Theme.panelBorder

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

                // Any new keystroke re-aims at the top result, which is where
                // whatever you are typing towards ends up.
                onTextChanged: list.currentIndex = 0

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.dismissed();
                    } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_J && event.modifiers & Qt.ControlModifier)) {
                        list.incrementCurrentIndex();
                    } else if (event.key === Qt.Key_Up || (event.key === Qt.Key_K && event.modifiers & Qt.ControlModifier)) {
                        list.decrementCurrentIndex();
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.accepted(list.currentIndex);
                    } else if (root.keyHandler && root.keyHandler(event)) {
                        // claimed by the host
                    } else {
                        return;   // not ours: let it reach the text field
                    }

                    event.accepted = true;
                }

                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    visible: input.text === ""
                    text: root.placeholder
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
                bottom: footerLabel.visible ? footerLabel.top : parent.bottom
                topMargin: 6
                bottomMargin: 12
            }

            clip: true
            model: root.model
            delegate: root.delegate

            // Keeps the keyboard selection on screen when it walks past the
            // bottom of the visible rows.
            highlightMoveDuration: 120
            preferredHighlightBegin: 40
            preferredHighlightEnd: height - 40
            highlightRangeMode: ListView.ApplyRange
        }

        BarText {
            id: footerLabel

            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 14
                rightMargin: 14
                bottomMargin: 4
            }

            text: root.footer
            visible: text !== ""
            font.weight: Font.Normal
            font.pixelSize: Theme.fontSize - 2
            opacity: 0.55
            elide: Text.ElideRight
        }
    }
}
