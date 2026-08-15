// A search-and-choose overlay: dimmed screen, centred panel, one text field,
// one keyboard-driven list.
//
// Both the app launcher and the clipboard picker are this with a different
// model and a different delegate, which is why it lives here rather than being
// written twice and then drifting apart.
//
// Set `columns` above 1 and the list becomes a grid instead -- same chrome,
// same keys, same search. That exists for the wallpaper chooser, where the
// thing being chosen is a picture and a row of filenames would be useless.

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

    // One column is the list; more than one is a grid. The grid needs an
    // explicit cell height, since a picture has no implicit one -- hosts bind
    // it to `cellWidth`, which is why that is published.
    property int columns: 1
    property int cellHeight: 0

    readonly property bool grid: root.columns > 1
    readonly property real cellWidth: root.grid ? Math.floor(gridView.width / root.columns) : 0

    // The view in use. Untyped on purpose: ListView and GridView share
    // `currentIndex` and `contentHeight` but only through their own
    // meta-objects, so a property declared as Flickable could not reach either.
    readonly property var view: root.grid ? gridView : list

    readonly property alias query: input.text
    readonly property int selected: root.view ? root.view.currentIndex : 0

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
            root.view.currentIndex = 0;
            input.forceActiveFocus();
        }
    }

    // Movement is index arithmetic rather than the views' own
    // increment/decrement, because those two do not share a vocabulary:
    // ListView has incrementCurrentIndex, GridView has moveCurrentIndexDown.
    // Doing the sums here means one set of keys drives both, and a list is
    // simply the case where `columns` is 1.
    //
    // Clamped rather than wrapped, matching Power's grid: an aim that falls off
    // one edge and reappears at the other is an aim the eye has to go and find.
    function move(dx, dy) {
        const count = root.model ? root.model.length : 0;
        if (count === 0)
            return;

        const cols = root.columns;
        let col = root.view.currentIndex % cols;
        let row = Math.floor(root.view.currentIndex / cols);

        col = Math.max(0, Math.min(cols - 1, col + dx));
        row = Math.max(0, Math.min(Math.ceil(count / cols) - 1, row + dy));

        root.view.currentIndex = Math.min(count - 1, row * cols + col);
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

        // Everything that is not the view: the search row, the footer, and the
        // three margins between them. The view gets exactly the rest, which is
        // what lets the grid below snap to it.
        readonly property int chrome: searchRow.height + (footerLabel.visible ? footerLabel.height + 6 : 0) + 30

        height: {
            const full = panel.chrome + root.view.contentHeight;
            if (!root.grid || full <= root.maxHeight)
                return Math.min(root.maxHeight, full);

            // A grid tall enough to scroll is cut to a whole number of rows.
            // Left to the cap it stops partway down a picture, and a row sliced
            // through the middle reads as a panel that failed to draw rather
            // than one with more underneath.
            const rows = Math.max(1, Math.floor((root.maxHeight - panel.chrome) / root.cellHeight));
            return panel.chrome + rows * root.cellHeight;
        }
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
                onTextChanged: root.view.currentIndex = 0

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.dismissed();
                    } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_J && event.modifiers & Qt.ControlModifier)) {
                        root.move(0, 1);
                    } else if (event.key === Qt.Key_Up || (event.key === Qt.Key_K && event.modifiers & Qt.ControlModifier)) {
                        root.move(0, -1);
                    } else if (root.grid && event.key === Qt.Key_Right) {
                        // Only claimed in a grid. In a list these are the text
                        // cursor's, and the query is the only thing to edit.
                        root.move(1, 0);
                    } else if (root.grid && event.key === Qt.Key_Left) {
                        root.move(-1, 0);
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.accepted(root.view.currentIndex);
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

        Item {
            id: viewArea

            anchors {
                top: searchRow.bottom
                left: parent.left
                right: parent.right
                bottom: footerLabel.visible ? footerLabel.top : parent.bottom
                topMargin: 6
                bottomMargin: 12
            }

            // Both views exist and only one is fed. Handing the idle one an
            // empty model rather than hiding it matters: a hidden view still
            // builds a delegate per row, which for the grid is a decoded image
            // apiece.

            ListView {
                id: list

                anchors.fill: parent
                visible: !root.grid

                clip: true
                model: root.grid ? [] : root.model
                delegate: root.delegate

                // Keeps the keyboard selection on screen when it walks past the
                // bottom of the visible rows.
                highlightMoveDuration: 120
                preferredHighlightBegin: 40
                preferredHighlightEnd: height - 40
                highlightRangeMode: ListView.ApplyRange
            }

            GridView {
                id: gridView

                anchors.fill: parent
                visible: root.grid

                clip: true
                model: root.grid ? root.model : []
                delegate: root.delegate

                // Floored at 1: in list mode this view is idle and both figures
                // are 0, which GridView complains about.
                cellWidth: Math.max(1, root.cellWidth)
                cellHeight: Math.max(1, root.cellHeight)

                // The range is where the top of the selected cell may sit, so
                // it stops one cell short of the bottom -- otherwise the row
                // being aimed at is allowed to hang half off the panel.
                highlightMoveDuration: 120
                preferredHighlightBegin: 0
                preferredHighlightEnd: Math.max(0, height - root.cellHeight)
                highlightRangeMode: GridView.ApplyRange
            }
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
