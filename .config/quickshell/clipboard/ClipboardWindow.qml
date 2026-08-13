// The clipboard picker: a Picker over cliphist history.

import QtQuick
import Quickshell
import "root:/theme"
import "root:/services"
import "root:/components"

Picker {
    id: root

    open: Clipboard.open
    placeholder: "Search clipboard"
    model: Clipboard.results

    // Wider and shorter rows than the launcher: these are lines of text, not
    // named things with icons, so horizontal room is worth more than height.
    panelWidth: 720

    footer: Clipboard.confirmingWipe ? "Clear the entire clipboard history?  Enter to confirm, Esc to cancel" : "Enter copies   ·   Del removes one   ·   Shift+Del clears all"

    onQueryChanged: Clipboard.query = root.query

    onDismissed: {
        // Escape backs out of the wipe prompt first, rather than closing the
        // whole picker -- otherwise the only way to decline is to reopen it.
        if (Clipboard.confirmingWipe) {
            Clipboard.confirmingWipe = false;
            return;
        }

        Clipboard.hide();
    }

    onAccepted: index => {
        // Enter means "yes" while a wipe is pending, rather than copying
        // whatever happened to be highlighted behind the prompt.
        if (Clipboard.confirmingWipe) {
            Clipboard.wipe();
            return;
        }

        const entry = Clipboard.results[index];
        Clipboard.hide();
        Clipboard.copy(entry);
    }

    // Delete removes the highlighted entry and leaves the picker open, which is
    // what the old script's separate "delete mode" existed to do -- pruning is
    // usually several entries in a row, and reopening a launcher between each
    // one was the annoying part.
    keyHandler: event => {
        if (event.key !== Qt.Key_Delete)
            return false;

        if (event.modifiers & Qt.ShiftModifier)
            Clipboard.confirmingWipe = true;
        else
            Clipboard.remove(Clipboard.results[root.selected]);

        return true;
    }

    delegate: ClipRow {
        required property var modelData
        required property int index

        entry: modelData
        width: ListView.view.width
        selected: ListView.isCurrentItem

        onActivated: root.accepted(index)
        onHovered: ListView.view.currentIndex = index
    }
}
