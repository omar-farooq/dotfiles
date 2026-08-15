// Disk, CPU and memory, behind a hover drawer.
//
// waybar's group also carried hyprland/language. Dropped: conf/keyboard.lua
// sets a single layout (gb) with no variants, so that module was a constant.
//
// Each readout is a letter, its recent history and the current number. waybar
// could only ever have shown the number -- a module was a string -- and a bare
// percentage is the least useful reading of a machine's load: it cannot tell
// you whether you are watching a spike arrive or a spike leave. The sparkline
// is the part that answers that, and the number stays for precision.
//
// Clicking anywhere on the drawer opens the panel with the per-core detail.

import QtQuick
import Quickshell
import "root:/theme"
import "root:/services"
import "root:/components"

Drawer {
    id: root

    icon: Icons.system

    // Drawers are inert by default, because ToolsGroup's contents are buttons
    // and the drawer must not eat their clicks. This one holds only text, so
    // the whole pill can be the target.
    interactive: true

    onClicked: hardware.toggle()

    Readout {
        label: "D"
        value: Sys.disk
        history: Sys.diskHistory
    }

    Readout {
        label: "C"
        value: Sys.cpu
        history: Sys.cpuHistory
    }

    Readout {
        label: "M"
        value: Sys.memory
        history: Sys.memoryHistory
    }

    // Anchored to the drawer, which changes width as it opens and closes --
    // harmless here, because the panel hangs from the pill's right edge and the
    // drawer grows leftwards, so the edge it is pinned to never moves.
    HardwarePopout {
        id: hardware

        anchorItem: root
    }

    // One metric: initial, history, number. The initials are waybar's, kept
    // because three letters in a fixed order are quicker to read than three
    // icons that all mean "computer".
    component Readout: Row {
        id: readout

        property string label: ""
        property int value: 0
        property var history: []

        height: Theme.pillHeight
        spacing: 5

        BarText {
            text: readout.label
            font.weight: Font.Normal
            opacity: 0.55
        }

        Sparkline {
            anchors.verticalCenter: parent.verticalCenter
            count: 12
            height: 12
            values: readout.history
        }

        BarText {
            // Fixed width, right-aligned, rather than sized to the text: the
            // number changes every three seconds, and letting it set its own
            // width means the whole drawer shuffles sideways each time one
            // crosses ten or a hundred.
            width: 34
            horizontalAlignment: Text.AlignRight
            text: `${readout.value}%`
            font.weight: Font.Normal
        }
    }
}
