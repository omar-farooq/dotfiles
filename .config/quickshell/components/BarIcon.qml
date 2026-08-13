// A glyph from the icon font. Same job as BarText, different family.
//
// Keeping glyphs in their own item rather than mixed into a sentence is what
// makes the single-family limit harmless: a Text that only ever holds icons can
// just ask for the icon font.

import QtQuick
import "root:/theme"

Text {
    color: Theme.text
    font.family: Theme.iconFont
    font.pixelSize: Theme.iconSize

    // See BarText: full height so a Row's top-alignment reads as centred.
    height: Theme.pillHeight
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}
