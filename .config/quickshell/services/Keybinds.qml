pragma Singleton

// The keybinding cheat sheet's data.
//
// Replaces the rofi half of hypr/scripts/keybindings.sh, but keeps that
// script's good idea: read the binds out of the running compositor rather than
// parsing a config file, so the list can never drift from what is actually
// bound. The labels are the `description` field on each hl.bind() call.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool open: false
    property string query: ""

    // { keys: "SUPER + CTRL + H", description: "Show keybindings", submap: "" }
    property var binds: []

    onOpenChanged: {
        root.query = "";

        // Re-read every time rather than caching: a Hyprland reload can change
        // the binds under us, and this is one cheap subprocess on open.
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
        if (!proc.running)
            proc.running = true;
    }

    Process {
        id: proc

        command: ["hyprctl", "-j", "binds"]

        stdout: StdioCollector {
            onStreamFinished: root.binds = root.parse(text)
        }
    }

    // Hyprland packs the modifiers into a bitmask. Listed in the order they
    // should read, not bit order, so every row says "SUPER + SHIFT" and never
    // "SHIFT + SUPER".
    readonly property var modifiers: [
        {
            bit: 64,
            name: "SUPER"
        },
        {
            bit: 4,
            name: "CTRL"
        },
        {
            bit: 8,
            name: "ALT"
        },
        {
            bit: 1,
            name: "SHIFT"
        }
    ]

    function parse(text) {
        let raw = [];
        try {
            raw = JSON.parse(text);
        } catch (e) {
            console.warn("keybinds: could not parse hyprctl output:", e);
            return [];
        }

        const out = [];

        for (const bind of raw) {
            // Undescribed binds are internal plumbing; the old script skipped
            // them rather than showing blank rows, and so does this.
            if (!bind.has_description || !bind.description)
                continue;

            const parts = root.modifiers.filter(m => (bind.modmask & m.bit) !== 0).map(m => m.name);
            parts.push(root.keyName(bind));

            out.push({
                keys: parts.join(" + "),
                description: bind.description,
                submap: bind.submap || ""
            });
        }

        // Sorted by the key combination, which groups every SUPER+SHIFT bind
        // together -- the arrangement you want when reading rather than
        // searching, and searching is handled by the filter anyway.
        out.sort((a, b) => a.keys.localeCompare(b.keys));

        return out;
    }

    // Binds made by keycode rather than name have an empty `key`.
    function keyName(bind) {
        if (bind.key && bind.key !== "")
            return bind.key;
        if (bind.keycode)
            return `code:${bind.keycode}`;
        return "?";
    }

    readonly property var results: {
        const q = root.query.trim().toLowerCase();
        if (q === "")
            return root.binds;

        // Matches the key combination as well as the description, so both
        // "what does SUPER+V do" and "clipboard" find the same row.
        return root.binds.filter(b => b.keys.toLowerCase().includes(q) || b.description.toLowerCase().includes(q));
    }
}
