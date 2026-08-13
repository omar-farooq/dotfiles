// The launcher button. Still rofi -- replacing it is a later phase.

import Quickshell
import "root:/theme"
import "root:/components"

Pill {
    accent: Theme.surfaceStrong

    // `-replace` so clicking twice doesn't stack instances.
    onClicked: Quickshell.execDetached(["rofi", "-show", "drun", "-replace"])
    onRightClicked: Quickshell.execDetached([`${Quickshell.env("HOME")}/.config/hypr/scripts/keybindings.sh`])

    BarText {
        text: "Apps"
    }
}
