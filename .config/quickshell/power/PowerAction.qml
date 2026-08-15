// One tile in the power menu: glyph, word, and the letter that fires it.
//
// Square on purpose (wleave's layout.json asked for "button-aspect-ratio":
// "1/1"), and large -- these are pointer targets you want to hit first time,
// and the menu is only on screen for a second.

import QtQuick
import "root:/theme"
import "root:/components"

Rectangle {
    id: root

    property string label: ""
    property string icon: ""
    property string shortcut: ""
    property bool selected: false

    // Set by the window from the screen height -- see PowerWindow. The default
    // is only what a tile falls back to if something instantiates one loose.
    property int size: 150

    signal activated
    signal hovered

    implicitWidth: root.size
    implicitHeight: root.size

    radius: Theme.panelRadius

    // The selected tile is the one drawn in the anchor colour, the rest sit at
    // pill weight. Keeping unselected tiles visible rather than ghosted matters:
    // you have to be able to read all six before choosing one.
    color: root.selected ? Theme.surfaceStrong : Theme.surface
    opacity: root.selected ? 1 : Theme.pillOpacity

    border.width: 1
    border.color: root.selected ? Qt.rgba(1, 1, 1, 0.35) : Theme.panelBorder

    Behavior on color {
        ColorAnimation {
            duration: Theme.animation
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.animation
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 10

        BarIcon {
            anchors.horizontalCenter: parent.horizontalCenter

            text: root.icon

            // Far bigger than the bar's icons -- BarIcon only fixes the family
            // and the centring, so overriding the size is the intended use.
            // Sized off the tile so the glyph keeps its proportion as the tile
            // scales with the screen.
            font.pixelSize: Math.round(root.size * 0.3)
            height: Math.round(root.size * 0.36)
        }

        PanelText {
            anchors.horizontalCenter: parent.horizontalCenter

            text: root.label
            font.pixelSize: Theme.fontSize + 2
            font.weight: Font.DemiBold
        }

        // The accelerator, drawn as a key rather than said in words.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter

            width: 22
            height: 22
            radius: 6

            color: Qt.rgba(0, 0, 0, root.selected ? 0.35 : 0.22)

            PanelText {
                anchors.centerIn: parent

                text: root.shortcut.toUpperCase()
                font.pixelSize: Theme.fontSize - 2
                font.weight: Font.DemiBold
                opacity: 0.85
            }
        }
    }

    MouseArea {
        anchors.fill: parent

        // MouseArea rather than a TapHandler/HoverHandler pair: Qt's pointer
        // handlers get no events at all on these layer-shell surfaces.
        hoverEnabled: true

        onEntered: root.hovered()
        onClicked: root.activated()
    }
}
