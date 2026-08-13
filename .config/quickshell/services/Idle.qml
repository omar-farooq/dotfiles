pragma Singleton

// Whether hypridle is running, and a way to turn it off.
//
// The state is polled rather than tracked, because hypridle can be started and
// stopped from outside the bar (a keybind, a terminal) and the bar has no way
// to hear about it.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // True when idle-locking is armed.
    property bool active: false

    Process {
        id: check

        command: ["pgrep", "-x", "hypridle"]
        onExited: exitCode => root.active = exitCode === 0
    }

    function poll() {
        if (!check.running)
            check.running = true;
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }

    function toggle() {
        if (root.active)
            Quickshell.execDetached(["killall", "hypridle"]);
        else
            Quickshell.execDetached(["hypridle"]);

        // Re-read the real state shortly after rather than assuming the toggle
        // took: `hypridle` can exit immediately if a second copy is already
        // running, and optimistically flipping the icon would then lie.
        recheck.restart();
    }

    Timer {
        id: recheck

        interval: 400
        onTriggered: root.poll()
    }
}
