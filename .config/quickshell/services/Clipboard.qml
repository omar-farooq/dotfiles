pragma Singleton

// Clipboard history, backed by cliphist.
//
// Replaces ml4w/scripts/cliphist.sh, which piped `cliphist list` through rofi
// and the selection back through `cliphist decode | wl-copy`. Same three
// operations, but the picker stays open between deletes instead of the script's
// separate "delete mode", and nothing has to round-trip through a shell.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool open: false
    property string query: ""

    // { id: "9310", preview: "yay -S ...", raw: "9310\tyay -S ..." }
    property var entries: []

    // Set while a wipe is awaiting confirmation. Destructive and irreversible,
    // so it never happens on a single keystroke -- the old script asked through
    // a rofi Clear/Cancel prompt for the same reason.
    property bool confirmingWipe: false

    onOpenChanged: {
        root.query = "";
        root.confirmingWipe = false;

        // Re-read on open rather than polling: the history changes constantly
        // and nothing is looking at it while the picker is closed.
        if (root.open)
            root.refresh();
    }

    function toggle() {
        root.open = !root.open;
    }

    function hide() {
        root.open = false;
    }

    function refresh() {
        if (!listProc.running)
            listProc.running = true;
    }

    Process {
        id: listProc

        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: root.entries = root.parse(text)
        }
    }

    // `cliphist list` emits "<id>\t<preview>" per line. The id is all that any
    // later command needs, but delete wants the whole line back, so keep both.
    function parse(text) {
        const out = [];

        for (const line of text.split("\n")) {
            const tab = line.indexOf("\t");
            if (tab < 0)
                continue;

            out.push({
                id: line.slice(0, tab),
                preview: line.slice(tab + 1),
                raw: line
            });
        }

        return out;
    }

    readonly property var results: {
        const q = root.query.trim().toLowerCase();
        if (q === "")
            return root.entries;

        return root.entries.filter(e => e.preview.toLowerCase().includes(q));
    }

    // ------------------------------------------------------------------
    // Actions
    // ------------------------------------------------------------------

    // The id goes in as an argv element, not spliced into a shell string, so a
    // clipboard entry full of quotes and backticks cannot turn into a command.
    function copy(entry) {
        if (!entry)
            return;

        Quickshell.execDetached(["bash", "-c", 'cliphist decode "$1" | wl-copy', "--", entry.id]);
    }

    property string pendingDelete: ""

    function remove(entry) {
        if (!entry || deleteProc.running)
            return;

        // `cliphist delete` reads the line to remove from stdin. Writing it
        // rather than echoing it through a shell keeps arbitrary clipboard
        // content out of a command line entirely.
        root.pendingDelete = entry.raw;
        deleteProc.running = true;
    }

    Process {
        id: deleteProc

        command: ["cliphist", "delete"]
        stdinEnabled: true

        onStarted: {
            deleteProc.write(root.pendingDelete + "\n");
            // Closing stdin is the EOF that lets cliphist act and exit.
            deleteProc.stdinEnabled = false;
        }

        onExited: root.refresh()
    }

    function wipe() {
        wipeProc.running = true;
        root.confirmingWipe = false;
    }

    Process {
        id: wipeProc

        command: ["cliphist", "wipe"]
        onExited: root.refresh()
    }
}
