// Power menu. Still wleave -- replacing it is a later phase.

import Quickshell
import "root:/theme"
import "root:/components"

IconButton {
    icon: Icons.power

    onClicked: Quickshell.execDetached(["wleave"])
}
