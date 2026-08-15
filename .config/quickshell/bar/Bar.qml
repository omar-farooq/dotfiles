// One bar, for one monitor. Instantiated once per screen by shell.qml.

import QtQuick
import Quickshell
import "root:/theme"
import "root:/services"

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

    // Reserve the bar's height, and only that.
    //
    // The margin above it does not belong here even though it looks like it
    // should: the compositor adds a layer surface's own margin to whatever
    // exclusive zone it asks for. Reserving `barHeight + barMarginTop` counted
    // that gap twice -- `hyprctl monitors` reported 50 reserved for a bar whose
    // bottom edge is at 42 -- and every window on every monitor sat 8px lower
    // than it needed to, which read as the bar floating oddly far above them.
    exclusiveZone: Theme.barHeight

    // The bar's own empty space dismisses an open popout, the same as anywhere
    // else on screen would. PopoutCatcher deliberately cuts the whole bar strip
    // out of its input region so that pills keep working -- clicking another
    // pill should swap panels rather than costing a click to dismiss and
    // another to open -- and this fills the gaps that leaves. Declared before
    // the rows so it sits underneath them and never takes a pill's click.
    MouseArea {
        anchors.fill: parent

        onPressed: Popouts.closeAll()
    }

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

        // Where waybar's quicklinks group sat, so the bar reads the same.
        SpotifyPill {}

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

        // Beside the clock, where a bell has lived on every desktop since
        // there were bells -- and next to the tray, which is the other place
        // something arrives without being asked for.
        NotificationsPill {}

        PowerButton {}

        ClockPill {}
    }
}
