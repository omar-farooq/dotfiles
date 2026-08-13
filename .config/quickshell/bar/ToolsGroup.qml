// Clipboard, idle inhibitor, screen shader and wallpaper, behind a hover
// drawer.
//
// The wallpaper button has moved here from waybar's separate settings group.
// That group's other two entries are gone with ml4w: one launched the ML4W
// settings AppImage, the other switched waybar themes, and neither has anything
// to act on now.

import Quickshell
import "root:/theme"
import "root:/services"
import "root:/components"

Drawer {
    id: root

    icon: Icons.tools

    readonly property string scripts: `${Quickshell.env("HOME")}/.config`

    IconButton {
        icon: Icons.clipboard

        // Deleting and clearing are keys inside the picker now, so this no
        // longer needs the old script's separate right-click "delete mode" --
        // which reopened the same list with a different verb attached.
        onClicked: Clipboard.toggle()
    }

    IconButton {
        // Red when idle-locking is off, so a screen that is never going to lock
        // itself says so at a glance.
        icon: Idle.active ? Icons.idleOn : Icons.idleOff
        color: Idle.active ? Theme.text : Theme.danger

        onClicked: Idle.toggle()
        onRightClicked: Quickshell.execDetached(["hyprlock"])
    }

    IconButton {
        icon: Icons.shader

        // Left toggles the current filter, right steps to the next one.
        onClicked: Quickshell.execDetached([`${root.scripts}/hypr/scripts/hyprshade.sh`])
        onRightClicked: Quickshell.execDetached([`${root.scripts}/hypr/scripts/hyprshade.sh`, "next"])
    }

    IconButton {
        icon: Icons.wallpaper

        onClicked: Quickshell.execDetached(["waypaper"])
        onRightClicked: Quickshell.execDetached([`${root.scripts}/hypr/scripts/wallpaper-effects.sh`])
    }
}
