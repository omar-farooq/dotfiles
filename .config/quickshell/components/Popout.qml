// A panel that hangs off a bar pill.
//
// This is the first thing in the bar that has no waybar equivalent. A waybar
// module could relabel itself or launch something, and that was the whole
// vocabulary -- anything needing more had to become a separate window with its
// own placement problem (see how the old scripts reached for rofi). A popout
// keeps the pill as the summary and puts the detail one click below it.
//
// Placement is the compositor's job rather than ours: `anchor.item` hands
// Hyprland the pill's rectangle and it positions the surface from there, so the
// panel tracks its pill wherever the bar reflows to, lands on the monitor whose
// bar was clicked, and slides itself back inside the screen near an edge
// instead of being clipped. Nothing here computes a coordinate.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "root:/theme"

PopupWindow {
    id: root

    // Content goes inside the panel. See Pill for the reason the internals
    // below are assigned to `data` explicitly: once a component aliases its
    // default property, anything declared plainly in this file would land in
    // that alias instead -- here, inside itself.
    default property alias content: body.data

    // The pill this hangs from. Its window becomes the popout's parent window,
    // which is what keeps the two on the same monitor.
    property Item anchorItem: null

    property bool open: false

    // Space between the panel's edge and the content.
    property int padding: 14

    // The window the anchor pill lives in -- the bar. Needed for the focus grab
    // below, and reached through the attached property rather than by walking
    // `parent` up, which stops at the window's content item.
    readonly property QtObject hostWindow: anchorItem ? anchorItem.QsWindow.window : null

    visible: root.open && root.anchorItem !== null

    // Hangs from the pill's bottom-right corner and grows down and to the left,
    // so the panel lines up with the right-hand edge of its pill. Every pill
    // that will want a popout sits in the bar's right-hand section, which is
    // itself right-anchored, so this is the edge that stays still. SlideX lets
    // a panel wider than the space left of its pill shuffle right to fit.
    anchor.item: root.anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.adjustment: PopupAdjustment.SlideX

    // The window is a gap taller than the panel, and the panel sits at the
    // bottom of it, so the gap between pill and panel is empty window rather
    // than a positioning offset. `anchor.margins` looks like the obvious way to
    // ask for that gap and is not: its margins inset the anchor rectangle, so a
    // bottom margin pulls the panel *up* over the pill. The mask below is what
    // stops the empty strip swallowing clicks meant for the bar behind it.
    implicitWidth: Math.max(1, Math.round(body.childrenRect.width)) + padding * 2
    implicitHeight: Math.max(1, Math.round(body.childrenRect.height)) + padding * 2 + Theme.gap

    color: "transparent"
    mask: Region {
        item: panel
    }

    data: [
        // Clicking anywhere outside the popout closes it. The bar is in the
        // grab alongside the panel so that clicking the pill a second time
        // still reaches the pill: without it the grab would eat that click to
        // dismiss itself and the pill's own toggle would reopen the popout in
        // the same gesture. The cost is that clicking a *different* pill leaves
        // this one open.
        HyprlandFocusGrab {
            windows: root.hostWindow ? [root, root.hostWindow] : [root]
            active: root.visible

            onCleared: root.open = false
        },
        Rectangle {
            id: panel

            anchors.fill: parent
            anchors.topMargin: Theme.gap

            radius: Theme.panelRadius
            color: Theme.panel
            border.width: 1
            border.color: Theme.panelBorder

            Item {
                id: body

                x: root.padding
                y: root.padding
            }
        }
    ]
}
