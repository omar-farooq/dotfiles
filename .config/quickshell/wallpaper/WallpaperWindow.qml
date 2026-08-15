// The wallpaper chooser: a Picker in grid mode over ~/wallpaper.
//
// This is the one picker whose subject is a picture rather than a word, which
// is what put the grid mode into Picker. Everything else -- the dim, the
// keyboard grab, the search field, Escape and Return -- is the same overlay the
// launcher and the clipboard use, so the chooser behaves like the rest of the
// shell rather than like the GTK window it replaces.

import QtQuick
import Quickshell
import "root:/theme"
import "root:/services"
import "root:/components"

Picker {
    id: root

    open: Wallpaper.open
    placeholder: "Wallpaper"
    model: Wallpaper.results

    // Four rather than waypaper's three. The panel is capped below, so a column
    // buys visible rows rather than width: three showed six wallpapers of the
    // hundred-odd in the folder, which is eighteen pages to look through.
    columns: 4

    // Wider and taller than the text pickers, because the whole point is to see
    // the picture. Capped as well as proportional: 60% of the ultrawide is
    // 2064px, which would give tiles bigger than they need to be and a row that
    // takes a head-turn to read.
    panelWidth: Math.min(1300, Math.round(root.width * 0.6))
    maxHeight: Math.round(root.height * 0.72)

    // 16:9 for the picture -- the shape of two of the three monitors, and what
    // the cached thumbnails are cut to -- plus the caption strip underneath.
    readonly property int captionHeight: 26

    cellHeight: Math.round(root.cellWidth * 9 / 16) + root.captionHeight

    footer: Wallpaper.current ? `Currently ${Wallpaper.basename(Wallpaper.current)}` : ""

    onQueryChanged: Wallpaper.query = root.query

    onDismissed: Wallpaper.hide()

    onAccepted: index => {
        const path = Wallpaper.results[index];
        Wallpaper.hide();
        Wallpaper.apply(path);
    }

    delegate: WallpaperTile {
        required property var modelData
        required property int index

        path: modelData
        current: modelData === Wallpaper.current
        captionHeight: root.captionHeight
        dpr: root.screen ? root.screen.devicePixelRatio : 1

        width: GridView.view.cellWidth
        height: GridView.view.cellHeight
        selected: GridView.isCurrentItem

        onActivated: root.accepted(index)
        onHovered: GridView.view.currentIndex = index
    }
}
