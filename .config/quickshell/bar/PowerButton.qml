// Power menu button. Opens the shell's own menu -- see power/PowerWindow.qml,
// which replaced wleave.

import Quickshell
import "root:/theme"
import "root:/services"
import "root:/components"

IconButton {
    icon: Icons.power

    onClicked: Power.toggle()
}
