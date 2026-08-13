// The launcher button. Still rofi -- replacing it is a later phase.

import Quickshell
import "root:/theme"
import "root:/services"
import "root:/components"

Pill {
    accent: Theme.surfaceStrong

    onClicked: Launcher.toggle()
    onRightClicked: Keybinds.toggle()

    BarText {
        text: "Apps"
    }
}
