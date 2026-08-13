pragma Singleton

// Pending package count, repo + AUR.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int count: 0

    // Thresholds carried over from the old updates.sh.
    readonly property bool many: count > 25
    readonly property bool lots: count > 100

    // checkupdates works against a throwaway copy of the sync database, so it
    // never touches the real one and never needs root -- which is the whole
    // reason to use it rather than `pacman -Qu`. The AUR half goes over the
    // network to the RPC endpoint, and is the expensive one.
    Process {
        id: proc

        command: ["bash", "-c", "{ checkupdates 2>/dev/null; yay -Qu --aur --quiet 2>/dev/null; } | wc -l"]

        stdout: StdioCollector {
            onStreamFinished: root.count = Number(text.trim()) || 0
        }
    }

    // Fifteen minutes, where waybar polled every sixty seconds. That old
    // interval meant an AUR RPC request every minute for the entire uptime of
    // the session -- needless load on someone else's server for a number that
    // moves a few times a day.
    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!proc.running)
            proc.running = true
    }

    // Called after an update run finishes, so the pill empties immediately
    // instead of sitting on a stale count for up to a quarter of an hour.
    function refresh() {
        if (!proc.running)
            proc.running = true;
    }
}
