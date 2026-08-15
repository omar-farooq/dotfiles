// Text in a popout's voice.
//
// BarText is not it: that one is pinned to the pill height so it centres itself
// inside a bar Row, which inside a panel makes every label taller than the row
// it sits in.

import QtQuick
import "root:/theme"

Text {
    color: Theme.text
    font.family: Theme.textFont
    font.pixelSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter
}
