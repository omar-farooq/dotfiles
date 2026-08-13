// Disk, CPU and memory, behind a hover drawer.
//
// waybar's group also carried hyprland/language. Dropped: conf/keyboard.lua
// sets a single layout (gb) with no variants, so that module was a constant.

import QtQuick
import Quickshell
import "root:/theme"
import "root:/services"
import "root:/components"

Drawer {
    icon: Icons.system

    BarText {
        text: `D ${Sys.disk}%`
        font.weight: Font.Normal
    }

    BarText {
        text: `C ${Sys.cpu}%`
        font.weight: Font.Normal
    }

    BarText {
        text: `M ${Sys.memory}%`
        font.weight: Font.Normal
    }
}
