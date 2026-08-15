// The bell, and how much has arrived since you last looked.
//
// waybar had no such module and could not have had one: dunst was a separate
// process with no way to tell the bar anything about its queue. The daemon
// lives in the shell now, so the count is a property rather than an IPC.

import QtQuick
import Quickshell
import "root:/theme"
import "root:/components"
import "root:/services"

Pill {
    id: root

    // Reads as an anchor while something is unread and as an ordinary pill
    // once it has been seen. The number alone is easy to miss on a bar this
    // wide; the colour is what catches an eye that was looking elsewhere.
    accent: Notifications.unread > 0 ? Theme.surfaceStrong : Theme.surface

    onClicked: history.toggle()

    // The notification card's own right click, moved somewhere you can reach
    // without aiming at a card that is about to expire.
    onRightClicked: Notifications.dismissAll()

    BarIcon {
        // A struck-through bell for an empty history: the panel says "nothing
        // yet" in words, but the pill can say it without being opened.
        text: Notifications.history.length > 0 ? Icons.bell : Icons.bellQuiet
        opacity: Notifications.unread > 0 ? 1.0 : 0.75
    }

    BarText {
        text: Notifications.unread
        visible: Notifications.unread > 0
    }

    NotificationsPopout {
        id: history

        anchorItem: root
    }
}
