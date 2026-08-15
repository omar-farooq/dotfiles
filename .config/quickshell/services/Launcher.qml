pragma Singleton

// Application search, replacing `rofi -show drun`.
//
// The matching lives here rather than in the window so it can be reasoned about
// on its own: what shows up, and in what order, is the whole job of a launcher,
// and burying it in a delegate makes it untunable.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool open: false
    property string query: ""

    // -----------------------------------------------------------------
    // Pins and usage
    //
    // With an empty box the launcher used to list every application in
    // alphabetical order, which is a directory rather than a launcher -- the
    // eight things actually opened day to day were scattered through fifty.
    // Typing found them, but only if you already knew you were going to type.
    //
    // Applications are keyed by their desktop id ("firefox",
    // "org.fontforge.FontForge"). `DesktopEntry.id` is missing from Quickshell's
    // type information but is readable at runtime, and `DesktopEntries.byId`
    // turns one back into an entry -- which is what lets a pin outlive a
    // restart without storing anything else about the application.
    // -----------------------------------------------------------------

    // Pinned ids, in the order they were pinned.
    property var favourites: []

    // id -> { count, last }. Launch tally and the last time, for frecency.
    property var usage: ({})

    // Under XDG state rather than the config tree: it is a record of what has
    // been done, not a setting, and it would otherwise turn every launch into a
    // dirty file in the dotfiles repo.
    //
    // Spelled out rather than `Quickshell.statePath()`, which resolves to
    // ~/.local/state/quickshell/by-shell/<shell id>/ -- correct, and impossible
    // to find or hand-edit when you want to fix a pin without opening the
    // launcher.
    readonly property string stateDir: `${Quickshell.env("HOME")}/.local/state/quickshell`
    readonly property string stateFile: `${root.stateDir}/launcher.json`

    // FileView writes the file but not the directory holding it.
    Process {
        running: true
        command: ["mkdir", "-p", root.stateDir]
    }

    FileView {
        id: store

        path: root.stateFile
        preload: true

        // Rewritten whole on every launch, so a torn write would lose the lot.
        atomicWrites: true

        // No watchChanges: this shell is the only writer, and reloading our own
        // write would just feed it back to us.
        onLoaded: root.adopt(store.text())
    }

    function adopt(text) {
        try {
            const data = JSON.parse(text);
            root.favourites = data.favourites || [];
            root.usage = data.usage || ({});
        } catch (e) {
            // A missing or corrupt file is not worth refusing to launch over.
            root.favourites = [];
            root.usage = ({});
        }
    }

    function persist() {
        store.setText(JSON.stringify({
            favourites: root.favourites,
            usage: root.usage
        }, null, 2));
    }

    function isFavourite(entry) {
        return !!entry && root.favourites.indexOf(entry.id) !== -1;
    }

    function toggleFavourite(entry) {
        if (!entry || !entry.id)
            return;

        // Copied rather than mutated: QML only notices a `var` property when it
        // is assigned, so pushing into the existing array would update nothing.
        const next = root.favourites.slice();
        const at = next.indexOf(entry.id);

        if (at === -1)
            next.push(entry.id);
        else
            next.splice(at, 1);

        root.favourites = next;
        root.persist();
    }

    function record(entry) {
        if (!entry || !entry.id)
            return;

        const next = Object.assign({}, root.usage);
        const prev = next[entry.id] || {
            count: 0,
            last: 0
        };

        next[entry.id] = {
            count: prev.count + 1,
            last: Date.now()
        };

        root.usage = next;
        root.persist();
    }

    // Launch count, halved for every fortnight since it was last opened. Plain
    // recency would put whatever was opened last on top and reshuffle the list
    // after every single launch; a plain tally would let something used heavily
    // one afternoon sit at the top for months. This decays out of the way.
    function frecency(entry) {
        const seen = root.usage[entry.id];

        if (!seen)
            return 0;

        const days = (Date.now() - seen.last) / 86400000;
        return seen.count * Math.pow(0.5, days / 14);
    }

    // What an empty box shows: pins in the order they were pinned, then
    // everything used before by frecency, then the rest alphabetically. The
    // tail is kept rather than cut, because "show me everything" is still a
    // thing a launcher should do -- it is just no longer the only thing.
    function browseOrder() {
        const pinned = [];
        const recent = [];
        const rest = [];

        for (const id of root.favourites) {
            const entry = DesktopEntries.byId(id);

            // A pin whose application has been uninstalled is skipped rather
            // than dropped, so reinstalling brings it back where it was.
            if (entry && !entry.noDisplay)
                pinned.push(entry);
        }

        for (const entry of DesktopEntries.applications.values) {
            if (entry.noDisplay || root.isFavourite(entry))
                continue;

            if (root.usage[entry.id])
                recent.push(entry);
            else
                rest.push(entry);
        }

        recent.sort((a, b) => root.frecency(b) - root.frecency(a));
        rest.sort((a, b) => a.name.localeCompare(b.name));

        return pinned.concat(recent, rest);
    }

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

        // Browsing is a different job from searching, and ranking by relevance
        // when there is no query to be relevant to is what produced the
        // alphabetical wall.
        if (q === "")
            return root.browseOrder();

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
