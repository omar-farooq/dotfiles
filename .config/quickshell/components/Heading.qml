// A section label inside a panel, with the rule that divides it from what came
// before.
//
// Lived inside VolumePopout while that was the only panel with sections, on the
// stated condition that it move here when a second one wanted them. The
// hardware panel is the second one.

import QtQuick
import "root:/theme"

Item {
    property alias text: label.text

    height: 22

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.panelBorder
    }

    PanelText {
        id: label

        anchors.bottom: parent.bottom
        font.pixelSize: Theme.fontSize - 3
        font.weight: Font.DemiBold
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 0.8
        opacity: 0.45
    }
}
