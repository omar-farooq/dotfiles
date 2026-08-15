// The power menu: six big targets in a 3x2 grid, one letter each.
//
// Not a Picker. Picker is search-and-choose over a list that can be any length,
// and this is a fixed six -- there is nothing to search, and typing a letter
// should *fire* an action rather than filter towards it. What it does share is
// the layer-shell setup below, which is the same overlay recipe.

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "root:/theme"
import "root:/services"
import "root:/components"

PanelWindow {
    id: root

    visible: Power.open

    // Exclusive keyboard, as Picker takes: without it Hyprland keeps first
    // refusal on keystrokes, and every letter accelerator here is also a bind.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Power.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-power"

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

    exclusiveZone: 0
    color: "transparent"

    onVisibleChanged: if (root.visible)
        keys.forceActiveFocus()

    // Darker than Picker's 0.3. A picker is a thing you do on top of your work
    // and want to see past; this is a decision about the session itself, and the
    // desktop behind it is no longer the point.
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.55
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Power.hide()
    }

    FocusScope {
        id: keys

        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            // The modifiers this window must not treat as part of a letter. It
            // holds an *exclusive* keyboard grab, so Hyprland's own binds do not
            // fire while it is up -- every chord arrives here instead.
            const chord = event.modifiers & (Qt.ControlModifier | Qt.MetaModifier | Qt.AltModifier);

            if (event.key === Qt.Key_Escape) {
                Power.hide();
            } else if (event.key === Qt.Key_Q && chord) {
                // SUPER+CTRL+Q, the bind that opened it, closing it again. Worth
                // handling by hand precisely because the grab means Hyprland
                // never sees the second press -- without this the toggle only
                // toggles one way, which reads as the menu having hung.
                Power.hide();
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H && event.modifiers & Qt.ControlModifier) {
                Power.move(-1, 0);
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L && event.modifiers & Qt.ControlModifier) {
                Power.move(1, 0);
            } else if (event.key === Qt.Key_Up) {
                Power.move(0, -1);
            } else if (event.key === Qt.Key_Down) {
                Power.move(0, 1);
            } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !chord) {
                Power.activate(Power.selected);
            } else if (chord) {
                // Any other chord is somebody reaching for a bind that is not
                // available right now. Swallowed rather than passed to the
                // letter matching below, so SUPER+S is not read as Shutdown.
            } else {
                // A bare letter fires its action outright, which is the whole
                // point of the accelerators -- SUPER+CTRL+Q then `s` shuts down
                // without ever looking at the screen. Note this is checked after
                // the ctrl-modified vi keys above, so ctrl+h moves rather than
                // hibernating.
                const index = Power.indexOfKey(event.text.toLowerCase());
                if (index < 0)
                    return;

                Power.activate(index);
            }

            event.accepted = true;
        }

        // Tiles scale with the screen rather than sitting at a fixed pixel size.
        // wleave asked for the same thing a different way -- "margin": "22%"
        // with a 1/1 aspect ratio, which on the 3440x1440 worked out around 400
        // a side. A fixed 150 looked stranded on that much glass. Clamped at
        // both ends so the TV does not get absurd tiles and a laptop panel
        // still gets usable ones.
        readonly property int tileSize: Math.max(150, Math.min(320, Math.round(root.height * 0.2)))

        Grid {
            id: grid

            anchors.centerIn: parent

            columns: Power.columns
            spacing: Theme.gap * 2

            Repeater {
                model: Power.actions

                PowerAction {
                    required property var modelData
                    required property int index

                    label: modelData.label
                    icon: modelData.icon
                    shortcut: modelData.key
                    size: keys.tileSize

                    selected: Power.selected === index

                    onActivated: Power.activate(index)
                    onHovered: Power.selected = index
                }
            }
        }

        BarText {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: grid.bottom
                topMargin: Theme.gap * 3
            }

            // The letters are already on every button; this is for Escape,
            // which is the one action with nowhere to be written.
            text: "Press a letter to choose, Esc to cancel"
            opacity: 0.5
        }
    }
}
