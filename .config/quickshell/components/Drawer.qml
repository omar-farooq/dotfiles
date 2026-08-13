// waybar's `group/drawer`: a handle glyph that expands on hover to reveal the
// rest of the group. Used for the hardware readouts and the tools -- things
// worth having to hand but not worth permanent bar space.
//
// Contents are revealed to the *left* of the handle, because both drawers sit
// in the right-hand section of the bar and that section is right-anchored, so
// growing leftwards is the direction that doesn't shove everything else along.

import QtQuick
import "root:/theme"

Pill {
    id: root

    // Children of a Drawer land in the revealed area. The name differs from
    // Pill's own `content` on purpose: redeclaring an inherited property name
    // is an error, and this component needs both -- `items` for what callers
    // pass in, and Pill's `content` for the handle-and-drawer assembly below.
    default property alias items: revealed.data

    property string icon: ""

    readonly property bool expanded: hover.hovered

    interactive: false
    padding: 8
    spacing: 0

    content: [
        // Parented to Pill's inner Row, so it senses hover across the handle
        // and the revealed contents alike -- which is what keeps the drawer
        // open while the pointer travels into it.
        HoverHandler {
            id: hover
        },
        // The clip is what makes this a drawer rather than a fade: the contents
        // keep their real width and get cropped, so they slide out from under
        // the handle instead of squashing.
        Item {
            width: root.expanded ? revealed.implicitWidth + Theme.gap : 0
            height: Theme.pillHeight
            clip: true

            Behavior on width {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            Row {
                id: revealed

                // Pinned to the right of the clip window, less one gap, so the
                // contents emerge from behind the handle rather than sliding in
                // from somewhere off to the left -- and so the last item does
                // not end up touching the handle glyph. The clip window is a
                // gap wider than the contents, which is where that space comes
                // from.
                x: parent.width - width - Theme.gap
                height: parent.height
                spacing: Theme.gap
            }
        },
        BarIcon {
            text: root.icon
            opacity: root.expanded ? 1.0 : 0.8

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animation
                }
            }
        }
    ]
}
