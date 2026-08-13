// Text in the bar's voice. Exists so no module has to restate the font stack.

import QtQuick
import "root:/theme"

Text {
    color: Theme.text
    font.family: Theme.textFont
    font.pixelSize: Theme.fontSize
    font.weight: Font.DemiBold

    // Full pill height, so that sitting at the top of a Row (which is where a
    // Row puts its children -- it manages x, not y) already reads as centred.
    // The alternative is anchoring each child inside the positioner, which Qt
    // warns about.
    height: Theme.pillHeight
    verticalAlignment: Text.AlignVCenter
}
