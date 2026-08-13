// Where notifications appear.

import QtQuick
import Quickshell
import "root:/theme"
import "root:/services"

PanelWindow {
    id: root

    // dunst pinned notifications to one screen -- `monitor = 0` with
    // `follow = none` -- rather than chasing focus, so this does the same. The
    // name is explicit because screen order is not stable enough to index into;
    // if that output is unplugged it falls back to whatever is first.
    readonly property string preferredScreen: "DP-1"

    screen: Quickshell.screens.find(s => s.name === root.preferredScreen) || Quickshell.screens[0]

    // No surface at all when there is nothing to show. An empty layer surface
    // still swallows clicks across whatever area it covers, which would leave a
    // dead strip along the top of the screen the rest of the time.
    visible: Notifications.list.values.length > 0

    color: "transparent"

    // Notifications are transient -- they must never push windows around.
    exclusiveZone: 0

    // Anchored on the top edge only, which leaves the compositor to centre it
    // horizontally: dunst's `origin = top-center`. The bar's own exclusive zone
    // already keeps this clear of it, so the margin is a gap, not an offset.
    anchors.top: true
    margins.top: 12

    implicitWidth: stack.implicitWidth
    implicitHeight: stack.implicitHeight

    Column {
        id: stack

        spacing: 8

        Repeater {
            model: Notifications.list

            delegate: NotificationCard {
                required property var modelData

                notification: modelData
            }
        }
    }
}
