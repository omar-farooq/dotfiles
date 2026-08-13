// The keybinding cheat sheet: a Picker over hyprctl binds.

import QtQuick
import Quickshell
import "root:/theme"
import "root:/services"
import "root:/components"

Picker {
    id: root

    open: Keybinds.open
    placeholder: "Search keybindings"
    model: Keybinds.results

    // Wider and taller than the launcher: this is a reference table being read,
    // not a list being aimed at, so showing more of it at once is the point.
    panelWidth: 760
    maxHeight: 560

    footer: `${Keybinds.results.length} of ${Keybinds.binds.length} bindings`

    onQueryChanged: Keybinds.query = root.query
    onDismissed: Keybinds.hide()

    // Nothing to launch -- the rows are documentation. Enter just closes, so
    // the reflex of hitting it after finding what you wanted does the
    // sensible thing rather than nothing.
    onAccepted: Keybinds.hide()

    delegate: KeybindRow {
        required property var modelData
        required property int index

        bind: modelData
        width: ListView.view.width
        selected: ListView.isCurrentItem

        onHovered: ListView.view.currentIndex = index
    }
}
