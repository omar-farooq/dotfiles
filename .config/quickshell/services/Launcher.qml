pragma Singleton

// Application search, replacing `rofi -show drun`.
//
// The matching lives here rather than in the window so it can be reasoned about
// on its own: what shows up, and in what order, is the whole job of a launcher,
// and burying it in a delegate makes it untunable.

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool open: false
    property string query: ""

    // Long lists are a scrolling exercise, not a search. Anything past this
    // means the query was too vague to be worth ranking further.
    readonly property int limit: 40

    function toggle() {
        root.open = !root.open;
    }

    function show() {
        root.open = true;
    }

    function hide() {
        root.open = false;
    }

    // Closing clears the query, so reopening always starts fresh rather than
    // showing the last search's results for a frame.
    onOpenChanged: if (!root.open)
        root.query = ""

    readonly property var results: {
        const q = root.query.trim().toLowerCase();
        const scored = [];

        for (const entry of DesktopEntries.applications.values) {
            // NoDisplay is how a .desktop file says "I am a file handler, not
            // an app" -- without this the list fills with MIME shims.
            if (entry.noDisplay)
                continue;

            const s = root.score(entry, q);
            if (s > 0)
                scored.push({
                    entry: entry,
                    score: s
                });
        }

        // Ties break alphabetically, so the order is stable between keystrokes
        // rather than shuffling as scores collide.
        scored.sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name));

        return scored.slice(0, root.limit).map(s => s.entry);
    }

    // Ranked bands rather than a single fuzzy number. A prefix match on the
    // name is what you almost always meant, and it should never lose to a
    // fuzzy hit somewhere in another app's description.
    function score(entry, q) {
        if (q === "")
            return 1;

        const name = (entry.name || "").toLowerCase();
        if (name.startsWith(q))
            return 1000 - name.length;   // shorter names first: "Files" over "Files (Admin)"
        if (name.includes(q))
            return 700;

        const generic = (entry.genericName || "").toLowerCase();
        const keywords = (entry.keywords || "").toString().toLowerCase();
        const comment = (entry.comment || "").toLowerCase();
        if (generic.includes(q) || keywords.includes(q))
            return 400;
        if (comment.includes(q))
            return 200;

        // Last resort: letters of the query appearing in order anywhere in the
        // name, which is what catches "chrm" for "Chromium".
        return root.subsequence(name, q) ? 100 : 0;
    }

    function subsequence(haystack, needle) {
        let i = 0;
        for (const ch of haystack) {
            if (ch === needle[i])
                i++;
            if (i === needle.length)
                return true;
        }
        return false;
    }
}
