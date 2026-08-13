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

        onClicked: Quickshell.execDetached([`${root.scripts}/ml4w/scripts/cliphist.sh`])
        onRightClicked: Quickshell.execDetached([`${root.scripts}/ml4w/scripts/cliphist.sh`, "d"])
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

        onClicked: Quickshell.execDetached([`${root.scripts}/hypr/scripts/hyprshade.sh`])
        onRightClicked: Quickshell.execDetached([`${root.scripts}/hypr/scripts/hyprshade.sh`, "rofi"])
    }

    IconButton {
        icon: Icons.wallpaper

        onClicked: Quickshell.execDetached(["waypaper"])
        onRightClicked: Quickshell.execDetached([`${root.scripts}/hypr/scripts/wallpaper-effects.sh`])
    }
}
