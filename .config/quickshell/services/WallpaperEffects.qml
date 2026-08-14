pragma Singleton

// The wallpaper effect currently in force, and the list to choose from.
//
// Replaces hypr/scripts/wallpaper-effects.sh, which listed
// ~/.config/hypr/effects/wallpaper/ into rofi and wrote the answer back to a
// settings file. That script was the last thing on the machine still calling
// rofi, so this retires the dependency outright.
//
// The effect itself is still applied by scripts/wallpaper.sh: it reads the name
// out of the settings file, sources the matching effect script, regenerates the
// image through imagemagick and pywal, and restarts hyprpaper. None of that is
// worth reimplementing in QML -- this only ever chose the name.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool open: false
    property string query: ""

    readonly property string home: Quickshell.env("HOME")
    readonly property string effectsDir: `${root.home}/.config/hypr/effects/wallpaper`
    readonly property string wallpaperScript: `${root.home}/.config/hypr/scripts/wallpaper.sh`

    // Still under ml4w/, but this is Omar's own tracked settings file rather
    // than upstream code -- wallpaper.sh reads the name from here, so moving it
    // would mean editing that script too, for no gain.
    readonly property string settingFile: `${root.home}/.config/ml4w/settings/wallpaper-effect.sh`

    // The name written in the settings file. "off" is a real value, not an
    // absence: wallpaper.sh compares against it explicitly.
    property string current: "off"

    property var names: []

    onOpenChanged: {
        root.query = "";

        // Re-read on open. Effects are files in a directory, so one can appear
        // without anything telling us, and nothing is looking while it is shut.
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

        command: ["ls", "-1", root.effectsDir]

        stdout: StdioCollector {
            onStreamFinished: root.names = text.split("\n").map(l => l.trim()).filter(l => l !== "").sort()
        }
    }

    FileView {
        id: setting

        path: root.settingFile
        preload: true
        watchChanges: true

        // Rewritten whole and short, so an interrupted write would truncate the
        // only copy of the setting.
        atomicWrites: true

        onFileChanged: reload()
        onLoaded: root.current = setting.text().trim() || "off"

        // The regenerate runs here rather than beside the setText call: it reads
        // the file back, so starting it before the write lands is a race that
        // would apply the *previous* effect roughly half the time.
        onSaved: Quickshell.execDetached([root.wallpaperScript])
    }

    // "off" first: it is the reset rather than one more effect, and putting it
    // at the top of an alphabetical list is the only way it does not get lost
    // among the eight blur/brightness variants. The old script trailed it.
    readonly property var effects: ["off"].concat(root.names.filter(n => n !== "off"))

    readonly property var results: {
        const q = root.query.trim().toLowerCase();
        if (q === "")
            return root.effects;

        return root.effects.filter(n => n.toLowerCase().includes(q));
    }

    function apply(name) {
        if (!name || name === root.current)
            return;

        // Set locally as well as on disk so the tick moves the instant you pick,
        // rather than after the file watcher has been round.
        root.current = name;
        setting.setText(name + "\n");

        // Immediate acknowledgement, because regenerating an effect is several
        // seconds of imagemagick before anything visibly changes. The stack tag
        // is the one wallpaper.sh uses, so its "Using wallpaper effect..." notice
        // replaces this rather than stacking a second card on top of it.
        Quickshell.execDetached(["notify-send", "Wallpaper effect", name === "off" ? "Turning the effect off" : `Switching to ${name}`, "-h", "string:x-dunst-stack-tag:wallpaper"]);
    }
}
