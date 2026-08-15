// A screen-sized surface whose only job is to notice a click that was not meant
// for the open popout.
//
// Popouts used to close only by clicking their own pill a second time, because
// every way of asking the compositor "has the user gone elsewhere?" breaks a
// panel hanging off a layer surface that does not take keyboard focus.
// `HyprlandFocusGrab` over the popup *and* the bar delivers hover but silently
// swallows every button press, so the panel looks alive and ignores clicks; over
// the popup alone the grab never establishes and `cleared` closes the panel in
// the frame it opened; `PopupWindow.grabFocus` never maps the popup at all. All
// three want `WlrKeyboardFocus.OnDemand` on the bar, which would hand the bar
// the keyboard every time a pill is clicked.
//
// This asks the compositor nothing about focus. It is a transparent surface
// covering the screen, mapped only while a popout is open, whose *input region*
// is the screen minus the two places a click is not "elsewhere":
//
//   - the bar, so the pills keep working -- clicking another pill should swap
//     popouts, not cost a click to dismiss and another to open;
//   - the open panel, so everything inside it stays clickable.
//
// Both holes are cut out rather than stacked around, because stacking order
// between a layer surface and another surface's popup is not ours to decide --
// but an input region is.
//
// The cost: the dismissing click is consumed, so it closes the popout and does
// not also reach the window underneath. That is what a menu does on every
// desktop, and it is the price of not owning the keyboard.

import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/theme"
import "root:/services"

PanelWindow {
    id: root

    required property var modelData

    screen: modelData

    // The open popout, but only when it belongs to this screen. Its rectangle
    // gets cut out of this screen's input region, and a popout over on the
    // other monitor would otherwise punch that hole in the wrong place -- a
    // dead patch of screen with nothing in it.
    readonly property var popout: {
        const current = Popouts.current;
        return current && current.screen === root.screen ? current : null;
    }

    // No surface at all when nothing is open. An always-present overlay would
    // take the pointer away from every window on the machine for the sake of a
    // panel that is not there.
    visible: Popouts.current !== null

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    // Never reserve space, and never take the keyboard -- taking it is exactly
    // what made the other three approaches unworkable.
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-popout-catcher"

    // The whole screen, less the bar and less the panel.
    //
    // The panel's rectangle comes from the compositor rather than from us:
    // `relativeX`/`relativeY` are where the popup actually ended up relative to
    // its parent window, which matters because a panel near a screen edge gets
    // slid sideways to fit (see Popout's SlideX) and a computed guess would be
    // wrong in exactly that case. The bar's own origin is its margins, since it
    // is anchored to the top corners.
    //
    // Quickshell 0.3 warns that both are deprecated in favour of
    // `anchor.rect.x`/`y`. That is not a substitute here: `anchor.rect` is an
    // input we set ourselves (the pill's rectangle, see Popout), so reading it
    // back gives the zero we put there rather than where the popup landed.
    // Revisit if a later version exposes the placed geometry another way.
    mask: Region {
        x: 0
        y: 0
        width: root.width
        height: root.height

        Region {
            intersection: Intersection.Subtract

            x: 0
            y: 0
            width: root.width
            height: Theme.barMarginTop + Theme.barHeight
        }

        Region {
            intersection: Intersection.Subtract

            x: root.popout ? Theme.barMarginSide + root.popout.relativeX : 0
            y: root.popout ? Theme.barMarginTop + root.popout.relativeY : 0
            width: root.popout ? root.popout.width : 0
            height: root.popout ? root.popout.height : 0
        }
    }

    MouseArea {
        anchors.fill: parent

        // Any button, and on press rather than on release: dismissing should
        // feel like the panel got out of the way as you reached past it, not
        // like it waited to see whether you meant it.
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onPressed: Popouts.closeAll()
    }
}
