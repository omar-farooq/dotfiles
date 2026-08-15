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
import "root:/theme"
import "root:/services"

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

    // Open when Popouts says this is the one that is. Read-only deliberately:
    // an ordinary settable flag is exactly what allowed two panels on screen at
    // once, because setting one says nothing about the other. Ask through the
    // two functions below and the answer stays a single fact.
    readonly property bool open: Popouts.current === root

    function toggle() {
        Popouts.toggle(root);
    }

    function close() {
        Popouts.close(root);
    }

    // Space between the panel's edge and the content.
    property int padding: 14

    // Mapped exactly while open, and nothing cleverer than that.
    //
    // A QML fade was tried here and removed: making `visible` depend on an
    // animating opacity (`root.open || panel.opacity > 0`) means a reload that
    // tears the window down mid-animation leaves it mapped forever, because the
    // animation that would have carried opacity to zero dies with the old
    // generation. Three stranded panels sat on screen at once before that was
    // understood. Hyprland already fades a closing popup surface -- it is why a
    // screenshot taken just after a swap catches a ghost of the old panel -- so
    // the fade was buying a bug to get something the compositor gives free.
    visible: root.open && root.anchorItem !== null

    // Which of the pill's vertical edges the panel lines up with, and therefore
    // which way it grows.
    //
    // Right by default, because the bar's right-hand section is right-anchored:
    // a pill there keeps its right edge as neighbours change width, so a panel
    // pinned to it never slides about. The left section is anchored the other
    // way and the same reasoning inverts, so a pill over there (SpotifyPill) sets
    // this and gets a panel that lines up with its left edge instead. Getting
    // it wrong does not clip anything -- SlideX would shove the panel back on
    // screen -- it just leaves the panel visibly beside its pill rather than
    // under it.
    property bool alignLeft: false

    anchor.item: root.anchorItem
    anchor.edges: Edges.Bottom | (root.alignLeft ? Edges.Left : Edges.Right)
    anchor.gravity: Edges.Bottom | (root.alignLeft ? Edges.Right : Edges.Left)

    // Lets a panel wider than the space beside its pill shuffle along to fit.
    anchor.adjustment: PopupAdjustment.SlideX

    // The gap between pill and panel is built into the anchor rectangle: the
    // rect handed to the compositor is the pill's, extended a gap below it, so
    // the panel lands a gap lower without the window itself being any bigger.
    // `anchor.margins` looks like the way to ask for that and is the opposite
    // of it -- those margins *inset* this rect, so a bottom margin pulls the
    // panel up over the pill. Doing it with a taller window and an empty strip
    // at the top does work, but only with a `mask` to keep the strip from
    // swallowing clicks, and a mask is an input region: get it slightly wrong
    // and the whole panel silently stops taking input.
    anchor.rect.x: 0
    anchor.rect.y: 0
    anchor.rect.width: root.anchorItem ? root.anchorItem.width : 0
    anchor.rect.height: (root.anchorItem ? root.anchorItem.height : 0) + Theme.gap

    implicitWidth: Math.max(1, Math.round(body.childrenRect.width)) + padding * 2
    implicitHeight: Math.max(1, Math.round(body.childrenRect.height)) + padding * 2

    color: "transparent"

    // Dismissal is the pill's job: clicking it again closes the popout, and
    // opening any other one closes this (see Popouts). There is deliberately no
    // click-outside-to-dismiss, because neither mechanism
    // for it survives a layer-shell parent that does not take keyboard focus,
    // and both fail in ways that look like something else:
    //
    //   - `HyprlandFocusGrab` listing the popup *and* the bar delivers hover to
    //     the panel but silently swallows every button press. The panel looks
    //     alive, highlights under the pointer, and ignores clicks -- which
    //     reads as a dead button, not as a grab problem. This cost an evening.
    //   - Listing only the popup stops eating clicks, but then the grab never
    //     establishes: `cleared` fires immediately, so the panel closes in the
    //     same frame it opens.
    //   - `grabFocus` does not map the popup at all.
    //
    // Getting it back means making the bar `WlrKeyboardFocus.OnDemand`, which
    // hands the bar the keyboard every time a pill is clicked. That is a worse
    // trade than clicking the pill twice.

    data: [
        Rectangle {
            id: panel

            anchors.fill: parent

            radius: Theme.panelRadius
            color: Theme.panel
            border.width: 1
            border.color: Theme.panelBorder

            // Sized to what it holds rather than left at zero. Qt only culls a
            // subtree from hit-testing when the parent clips, so a zero-sized
            // slot would still have worked -- but every readout of this item's
            // geometry, this window's size included, would have been a lie.
            Item {
                id: body

                x: root.padding
                y: root.padding
                width: childrenRect.width
                height: childrenRect.height
            }
        }
    ]
}
