// Pending package count.

import Quickshell
import "root:/theme"
import "root:/services"
import "root:/components"

Pill {
    id: root

    // Nothing to say when there is nothing to install. waybar drew a "0" pill,
    // which is a permanent piece of furniture reporting the absence of news.
    visible: Updates.count > 0

    accent: Updates.lots ? Theme.danger : (Updates.many ? Theme.warning : Theme.surface)

    onClicked: {
        // The floating class is what conf/windowrules picks up to give this its
        // own window rather than tiling it into whatever is open.
        Quickshell.execDetached(["alacritty", "--class", "dotfiles-floating", "-e", "yay", "-Syu"]);
    }

    // Recount now, rather than waiting out the poll interval.
    onRightClicked: Updates.refresh()

    BarIcon {
        text: Icons.updates
    }

    BarText {
        text: Updates.count
    }
}
