// One bar, for one monitor. Instantiated once per screen by shell.qml.

import QtQuick
import Quickshell
import "root:/theme"

PanelWindow {
    id: bar

    // Handed to us by Variants in shell.qml -- the ShellScreen this bar belongs
    // to. Every module that has per-monitor behaviour (the workspace row, the
    // window title) is given it explicitly rather than asking for "the focused
    // monitor", which is a different thing and changes under the cursor.
    required property var modelData

    screen: modelData

    // The bar itself draws nothing; the pills are the only visible things, so
    // the wallpaper shows through the gaps between them.
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: Theme.barMarginTop
        left: Theme.barMarginSide
        right: Theme.barMarginSide
    }

    implicitHeight: Theme.barHeight

    // Reserve the bar's height *and* the gap above it, so a maximised window
    // stops below the bar rather than sliding under it.
    exclusiveZone: Theme.barHeight + Theme.barMarginTop

    // Three separately anchored rows rather than one three-cell layout. The
    // centre group then stays centred on the screen however wide the window
    // title on the left grows -- which is what waybar's modules-center did, and
    // what a plain RowLayout with a spacer would not.
    Row {
        id: leftSection

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }
        spacing: Theme.gap

        AppMenu {}

        WindowTitle {
            screen: bar.modelData
        }
    }

    Row {
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }
        spacing: Theme.gap

        Workspaces {
            screen: bar.modelData
        }
    }

    Row {
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        spacing: Theme.gap

        UpdatesPill {}

        VolumePill {}

        NetworkPill {}

        HardwareGroup {}

        ToolsGroup {}

        TrayRow {}

        PowerButton {}

        ClockPill {}
    }
}
