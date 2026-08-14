// The workspace row.
//
// This is the most deliberately tuned part of the old waybar config, and the
// three behaviours below were each fixed in response to a specific annoyance.
// They are requirements, not preferences:
//
//   1. Per-monitor. Each bar lists only the workspaces living on its own
//      output, so the ultrawide stops advertising what is open on the TV.
//   2. Scrolling walks the row, and scrolling up past the end grows it.
//   3. Each pill shows an icon per window, so the bar says what is running
//      where without having to go and look.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "root:/theme"
import "root:/components"

Pill {
    id: root

    required property var screen

    // A backdrop for the buttons, not a button itself -- the buttons carry
    // their own padding and hover, so the pill keeps out of the way.
    interactive: false
    padding: 3
    spacing: 3

    // (1) This monitor's real workspaces, in order. Special workspaces have
    // negative ids and are not part of the row.
    //
    // No persistent/reserved list: the old `"*": 5` reserved ids 1-5 on *every*
    // bar, so DP-1 kept drawing a button for a workspace that actually sat on
    // DP-3.
    readonly property var workspaces: {
        const name = root.screen.name;
        return Hyprland.workspaces.values.filter(ws => ws.id > 0 && ws.monitor && ws.monitor.name === name).sort((a, b) => a.id - b.id);
    }

    // (3) Carried over from the waybar window-rewrite table. U+F2D0 (window
    // maximize) covers anything unmatched.
    // Written as \u escapes rather than pasted glyphs so the table stays
    // readable in a terminal and diffs sanely -- these are Font Awesome
    // codepoints, which most editors render as tofu anyway.
    readonly property var windowIcons: ({
        "firefox": "\uf269",
        "Alacritty": "\uf120",
        "Spotify": "\uf1bc",
        "Brave-browser": "\uf0ac",
        "Chromium": "\uf0ac",
        "Microsoft-edge": "\uf0ac",
        // Deliberately blank. The cava visualiser is a background window
        // wallpapered onto DP-1; give it an icon and every workspace on that
        // screen grows a phantom one.
        "alacritty-cava-bg": ""
    })

    // U+F2D0 window-maximize, for anything not matched above.
    readonly property string defaultWindowIcon: "\uf2d0"

    // The class comes off the Wayland handle, not off lastIpcObject.
    //
    // HyprlandToplevel.lastIpcObject is only filled in by a full `hyprctl
    // clients` query, and Quickshell runs one of those just once, at startup.
    // A window opened later is built from the `openwindow` event and keeps an
    // *empty* map for the rest of its life -- measured: zero keys, no `class`
    // in it at all. So within minutes of logging in every window was unmatched
    // and the row decayed into a line of identical U+F2D0 fallback glyphs.
    //
    // `wayland.appId` is pushed by the compositor as the toplevel appears, so
    // it is right immediately and stays right. It carries the same string
    // Hyprland reports as `class`, so the rewrite table above still applies
    // unchanged. lastIpcObject stays on as a fallback for any toplevel that
    // somehow arrives without a wl handle.
    function classOf(t) {
        return (t.wayland && t.wayland.appId) || (t.lastIpcObject ? t.lastIpcObject["class"] : "") || "";
    }

    function iconsFor(ws) {
        return ws.toplevels.values.map(t => {
            const icon = root.windowIcons[root.classOf(t)];
            return icon === undefined ? root.defaultWindowIcon : icon;
        }).filter(icon => icon !== "").join(" ");
    }

    Repeater {
        model: root.workspaces

        delegate: Rectangle {
            id: button

            required property var modelData

            readonly property string windows: root.iconsFor(modelData)

            // `active`, not `focused`. Only one workspace in the whole session
            // is focused, so keying the highlight off that leaves every bar but
            // the one under the keyboard with nothing lit. `active` is
            // per-monitor -- the workspace this screen is currently showing --
            // which is what waybar's button.active meant.
            readonly property bool current: modelData.active

            // The current workspace also gets a wider pill, so the row still
            // reads at a glance on a screen where the palette is low contrast
            // and opacity alone is a weak signal. waybar did this with
            // min-width: 40px on button.active.
            implicitWidth: Math.max(button.current ? 34 : 22, label.implicitWidth + 12)
            implicitHeight: 20
            radius: height / 2

            // The focused workspace is opaque, the rest recede. Same three-step
            // treatment the waybar CSS used -- active 1.0, hover 0.7, idle 0.4.
            color: Qt.rgba(Theme.surfaceStrong.r, Theme.surfaceStrong.g, Theme.surfaceStrong.b, button.current ? 1.0 : (hover.containsMouse ? 0.7 : 0.4))

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animation
                }
            }

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Theme.animation
                    easing.type: Easing.OutCubic
                }
            }

            // MouseArea, not TapHandler/HoverHandler -- see the input note in
            // Pill.qml. The wheel is forwarded up by hand because this sits on
            // top of the pill's own MouseArea, and a MouseArea swallows wheel
            // events whether or not it does anything with them.
            MouseArea {
                id: hover

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: button.modelData.activate()
                onWheel: event => root.wheel(event.angleDelta.y)
            }

            // Two items rather than one string: the id wants Fira Sans and the
            // window glyphs want Font Awesome, and a Text can only name one
            // family. Splitting them also lets the glyphs sit a shade smaller
            // than the digit without dragging the whole label down with them.
            Row {
                id: label

                anchors.centerIn: parent
                spacing: 5

                BarText {
                    // The leading id tells you which MOD+<n> gets back here.
                    text: button.modelData.id
                    height: button.height
                    color: button.modelData.urgent ? Theme.danger : Theme.text
                }

                BarIcon {
                    text: button.windows
                    visible: button.windows !== ""
                    height: button.height
                    font.pixelSize: Theme.iconSize - 2
                    color: button.modelData.urgent ? Theme.danger : Theme.text
                }
            }
        }
    }

    // (2) Scrolling. Pill emits this for the whole pill area, padding included.
    //
    // This shells out to ws-scroll.sh rather than dispatching from here because
    // the script also knows which ids conf/workspaces/default.lua pins to other
    // monitors: going past the end of a row mints a genuinely free id instead
    // of stealing a slot that belongs to another screen and dragging that
    // workspace over. Reimplementing that in QML would be a second copy of the
    // rule to keep in step.
    //
    // The screen is passed explicitly. The script used to infer it from which
    // monitor had focus, on the assumption that hovering a bar moves focus
    // there -- but conf/keyboard.lua sets input:mouse_refocus = false, so that
    // does not hold, and scrolling one bar could walk another screen's row.
    onWheel: delta => {
        Quickshell.execDetached([`${Quickshell.env("HOME")}/.config/hypr/scripts/ws-scroll.sh`, delta > 0 ? "next" : "prev", root.screen.name]);
    }
}
