pragma Singleton

// The six session actions, and which one the menu is aiming at.
//
// Replaces wleave (and wlogout before it). The layout it is porting lived in
// ~/.config/wleave/layout.json: six buttons, three per row, each with a single
// letter accelerator. Both the order and the letters are carried over verbatim
// -- they are muscle memory, and there is no reason a new menu should retrain
// them.
//
// The actions themselves still go through hypr/scripts/power.sh, exactly as
// wleave's buttons did. That is deliberate rather than lazy: `exit` is subtle
// (see the comment in that script -- `hyprctl dispatch exit` fails silently now
// the Hyprland config is Lua), and keeping one definition of what each word
// means is what stops the menu and the script drifting apart.

import QtQuick
import Quickshell
import "root:/theme"

Singleton {
    id: root

    property bool open: false

    // Which button is aimed at. Kept here rather than in the window so it
    // survives nothing in particular -- but it is what the letter keys, the
    // arrows and the pointer all write to, and one of those lives outside the
    // grid, so it is simpler as one property than as three.
    property int selected: 0

    readonly property string script: `${Quickshell.env("HOME")}/.config/hypr/scripts/power.sh`

    // Reading order is the grid order: three across, then three more. Lock
    // first because it is far and away the most used and the least destructive.
    readonly property var actions: [
        {
            id: "lock",
            label: "Lock",
            icon: Icons.lock,
            key: "l"
        },
        {
            id: "hibernate",
            label: "Hibernate",
            icon: Icons.hibernate,
            key: "h"
        },
        {
            id: "exit",
            label: "Exit",
            icon: Icons.logout,
            key: "e"
        },
        {
            id: "shutdown",
            label: "Shutdown",
            icon: Icons.power,
            key: "s"
        },
        {
            id: "suspend",
            label: "Suspend",
            icon: Icons.suspend,
            key: "u"
        },
        {
            id: "reboot",
            label: "Reboot",
            icon: Icons.reboot,
            key: "r"
        }
    ]

    readonly property int columns: 3

    onOpenChanged: {
        // Always reopens on Lock rather than wherever it was left. A power menu
        // is one of the few places where a remembered selection is a hazard:
        // open, press Return by reflex, and last time's Shutdown happens.
        if (root.open)
            root.selected = 0;
    }

    function toggle() {
        root.open = !root.open;
    }

    function hide() {
        root.open = false;
    }

    function indexOfKey(key) {
        return root.actions.findIndex(a => a.key === key);
    }

    // Grid movement. Deliberately clamped rather than wrapped -- six items in
    // two rows are all on screen at once, so wrapping would move the aim
    // somewhere the eye is not, and the thing being aimed at can power the
    // machine off.
    function move(dx, dy) {
        const cols = root.columns;
        const count = root.actions.length;

        let col = root.selected % cols;
        let row = Math.floor(root.selected / cols);

        col = Math.max(0, Math.min(cols - 1, col + dx));
        row = Math.max(0, Math.min(Math.ceil(count / cols) - 1, row + dy));

        root.selected = Math.min(count - 1, row * cols + col);
    }

    function activate(index) {
        const action = root.actions[index];
        if (!action)
            return;

        root.open = false;

        // Run after the menu has gone rather than beside it. wleave had the
        // same thing as `delay-command-ms: 100`, and it is not cosmetic: this
        // window holds an exclusive keyboard grab, and hyprlock wants one too,
        // so firing Lock while the overlay is still mapped is two surfaces
        // fighting over the keyboard at the moment you most need one of them to
        // win.
        runner.action = action.id;
        runner.start();
    }

    Timer {
        id: runner

        property string action: ""

        interval: 120
        repeat: false

        onTriggered: Quickshell.execDetached([root.script, runner.action])
    }
}
