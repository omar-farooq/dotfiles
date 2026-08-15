// Clipboard, idle inhibitor and wallpaper, behind a hover drawer.
//
// The wallpaper button has moved here from waybar's separate settings group.
// That group's other two entries are gone with ml4w: one launched the ML4W
// settings AppImage, the other switched waybar themes, and neither has anything
// to act on now.
//
// A screen shader button sat between the idle and wallpaper ones until
// 2026-08-16. Hyprland's screen shader is global -- one decoration:screen_shader
// for the whole session, with no per-output form -- and any shader makes the
// INNOCN on DP-3 flicker uncontrollably. DP-3 is a permanently connected desk
// monitor, so a guard that refused to enable a shader while it was attached
// would have been a delete with extra steps. Retired instead: unused since the
// flicker was found on 2026-08-13, and a stray right-click here used to cycle
// filters and apply each one as it passed.

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
        icon: Icons.wallpaper

        // Was waypaper, the last third-party window the desktop still opened.
        onClicked: Wallpaper.toggle()

        // Was wallpaper-effects.sh, which was rofi's last caller anywhere on
        // the machine. Now the same list in the shell's own picker.
        onRightClicked: WallpaperEffects.toggle()
    }
}
