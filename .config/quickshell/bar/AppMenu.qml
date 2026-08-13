// The launcher button. Still rofi -- replacing it is a later phase.

import Quickshell
import "root:/theme"
import "root:/services"
import "root:/components"

Pill {
    accent: Theme.surfaceStrong

    onClicked: Launcher.toggle()
    onRightClicked: Quickshell.execDetached([`${Quickshell.env("HOME")}/.config/hypr/scripts/keybindings.sh`])

    BarText {
        text: "Apps"
    }
}
