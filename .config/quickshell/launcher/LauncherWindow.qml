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

    onQueryChanged: Launcher.query = root.query
    onDismissed: Launcher.hide()

    onAccepted: index => {
        const entry = Launcher.results[index];
        Launcher.hide();

        if (entry)
            entry.execute();
    }

    delegate: AppRow {
        required property var modelData
        required property int index

        entry: modelData
        width: ListView.view.width
        selected: ListView.isCurrentItem

        onActivated: root.accepted(index)
        onHovered: ListView.view.currentIndex = index
    }
}
