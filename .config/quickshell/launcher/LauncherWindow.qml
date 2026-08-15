// The application launcher: a Picker over DesktopEntries.

import QtQuick
import Quickshell
import "root:/theme"
import "root:/services"
import "root:/components"

Picker {
    id: root

    open: Launcher.open
    placeholder: "Search applications"
    model: Launcher.results

    // Only worth saying while browsing: once you are typing, the list is a
    // search result and pinning it is not what you came for.
    footer: root.query === "" ? "Right-click or Ctrl+P to pin" : ""

    onQueryChanged: Launcher.query = root.query
    onDismissed: Launcher.hide()

    onAccepted: index => {
        const entry = Launcher.results[index];
        Launcher.hide();

        if (entry) {
            // Recorded before launching, not after: execute() hands off to the
            // application and this is the last moment we are certain of it.
            Launcher.record(entry);
            entry.execute();
        }
    }

    // Pinning from the keyboard, so browsing never has to become mousing.
    keyHandler: event => {
        if (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier)) {
            Launcher.toggleFavourite(Launcher.results[root.selected]);
            return true;
        }

        return false;
    }

    delegate: AppRow {
        required property var modelData
        required property int index

        entry: modelData
        width: ListView.view.width
        selected: ListView.isCurrentItem
        favourite: Launcher.isFavourite(modelData)

        onActivated: root.accepted(index)
        onHovered: ListView.view.currentIndex = index
        onTogglePin: Launcher.toggleFavourite(modelData)
    }
}
