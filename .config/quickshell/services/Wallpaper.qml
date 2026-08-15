pragma Singleton

// The wallpaper currently on screen, the folder to choose a new one from, and
// the thumbnail cache that makes choosing bearable.
//
// Replaces waypaper, which was a GTK application with its own window, its own
// config file and its own idea of the theme. It only ever did two things this
// desktop used: show the folder as a grid, and hand the chosen path to
// scripts/wallpaper.sh. That script still does all the real work -- pywal,
// hyprpaper, the blurred and square derivatives, the wallpaper effect -- so
// what follows is the chooser and nothing else, exactly as WallpaperEffects is
// the effect chooser and nothing else.
//
// The folder is the one waypaper was pointed at, spelled out here rather than
// read from ~/.config/waypaper/config.ini: that file is about to become dead
// weight, and a setting read from a dead application's config is a trap for
// whoever next wonders where the path comes from.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool open: false
    property string query: ""

    readonly property string home: Quickshell.env("HOME")
    readonly property string folder: `${root.home}/wallpaper`
    readonly property string wallpaperScript: `${root.home}/.config/hypr/scripts/wallpaper.sh`

    // wallpaper.sh's own record of what is set. It writes this on every run, so
    // watching it keeps the tick in the grid honest even when the wallpaper is
    // changed by something that never went through here -- the automation loop,
    // or the script run by hand.
    readonly property string currentFile: `${root.home}/.config/hypr/settings/current-wallpaper`

    // Under ~/.cache rather than ~/.local/state: every file in here is
    // regenerable from the folder in fourteen seconds, so it is exactly what
    // XDG means by a cache, and losing it costs nothing but that fourteen.
    readonly property string thumbDir: `${root.home}/.cache/quickshell/wallpaper-thumbs`

    property string current: ""
    property var files: []

    // Bumped when a thumbnailing pass finishes, so tiles that fell back to the
    // original can try the cache again. See WallpaperTile.
    property int thumbEpoch: 0

    onOpenChanged: {
        root.query = "";

        if (root.open) {
            // Re-read on open: wallpapers are files in a directory, so one can
            // appear without anything telling us.
            root.refresh();
            root.ensureThumbs();
        }
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

    readonly property var imageExtensions: ["jpg", "jpeg", "png", "webp", "bmp", "gif"]

    Process {
        id: listProc

        // maxdepth 1 because waypaper was configured with subfolders off, and a
        // wallpaper folder with a `.git` or a `screenshots/` in it should not
        // suddenly start offering their contents.
        command: ["find", root.folder, "-maxdepth", "1", "-type", "f"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.files = text.split("\n").filter(line => {
                    const ext = line.split(".").pop().toLowerCase();
                    return line !== "" && root.imageExtensions.includes(ext);
                })
                // By basename and case-insensitively: `find` returns directory
                // order, and a plain sort would file the four capitalised names
                // ahead of the hundred lower-case ones for no reason a person
                // scanning the grid would guess.
                .sort((a, b) => root.basename(a).toLowerCase().localeCompare(root.basename(b).toLowerCase()));
            }
        }
    }

    function basename(path) {
        return path.split("/").pop();
    }

    // -----------------------------------------------------------------
    // Thumbnails
    //
    // Measured before being written, because it is a cache and a cache needs a
    // reason. Drawing the 104 originals into the grid cost 338 MiB over an
    // empty-grid baseline and four seconds of CPU; the same grid on cached
    // thumbnails costs 68 MiB and about one. The shell is a process that runs
    // for weeks, so the difference is not a spike -- it is the floor the bar
    // sits at afterwards.
    //
    // The cache is built by one `sh` pass over the folder, skipping anything
    // already newer than its source, so the warm case is a fork and a stat per
    // file. Cold it is roughly fourteen seconds for this folder.
    // -----------------------------------------------------------------

    // Sized to cover the largest tile any monitor here asks for: the panel is
    // capped at 1300 logical pixels across four columns, and DP-3 draws at a
    // device pixel ratio of 2. Crop rather than fit, and 16:9 to match the tile
    // -- change the tile's shape and this has to follow, or every thumbnail is
    // cropped twice.
    readonly property string thumbSize: "800x450"

    function thumbFor(path) {
        return `${root.thumbDir}/${root.basename(path)}.jpg`;
    }

    function ensureThumbs() {
        if (!thumbProc.running)
            thumbProc.running = true;
    }

    Process {
        id: thumbProc

        command: ["sh", "-c", `
            dir=$1; out=$2; size=$3
            mkdir -p "$out" || exit 1
            for f in "$dir"/*; do
                [ -f "$f" ] || continue
                t="$out/\${f##*/}.jpg"
                if [ ! -e "$t" ] || [ "$f" -nt "$t" ]; then
                    # Never fatal: a thumbnail that cannot be made just means the
                    # tile draws the original instead, which works and is only
                    # heavier.
                    magick "$f" -auto-orient -thumbnail "$size^" -gravity center -extent "$size" -quality 82 "$t" || true
                fi
            done
        `, "sh", root.folder, root.thumbDir, root.thumbSize]

        onExited: root.thumbEpoch++
    }

    // Built once, twenty seconds after the shell loads, so the first person to
    // press SUPER+CTRL+W on a fresh machine finds it warm. Deferred rather than
    // immediate because login is already the busiest moment of the session, and
    // this is fourteen seconds of imagemagick that nothing is waiting on.
    Timer {
        running: true
        interval: 20000

        onTriggered: root.ensureThumbs()
    }

    // -----------------------------------------------------------------
    // Reading and setting
    // -----------------------------------------------------------------

    FileView {
        id: currentView

        path: root.currentFile
        preload: true
        watchChanges: true

        onFileChanged: reload()
        onLoaded: root.current = currentView.text().trim()
    }

    readonly property var results: {
        const q = root.query.trim().toLowerCase();
        if (q === "")
            return root.files;

        return root.files.filter(f => root.basename(f).toLowerCase().includes(q));
    }

    function apply(path) {
        if (!path)
            return;

        // Set locally as well, so the tick moves the moment you pick rather
        // than after wallpaper.sh has run pywal and written the file back.
        root.current = path;

        // Exactly what waypaper's post_command did: hand the path over and let
        // the script do the rest.
        Quickshell.execDetached([root.wallpaperScript, path]);
    }

    // SUPER+SHIFT+W, and the automation loop. Never repeats the wallpaper that
    // is already up -- with a hundred to choose from, the one time the dice
    // land on the current one reads as a broken keybind rather than a coincidence.
    //
    // `announce` is the difference between the two callers. From the keybind a
    // notification is the only feedback there is: wallpaper.sh takes a second or
    // two to restart hyprpaper, and you may well be looking at a full-screen
    // window, in which case nothing on screen ever changes -- so the card is
    // also the only place the new wallpaper's name appears. From the loop it
    // would be a card every sixty seconds forever, which is noise.
    function pickRandom(announce) {
        const pool = root.files.filter(f => f !== root.current);
        if (pool.length === 0)
            return false;

        const pick = pool[Math.floor(Math.random() * pool.length)];
        root.apply(pick);

        // The stack tag is the one wallpaper.sh uses, so its own effect notice
        // replaces this rather than stacking a second card on top of it.
        if (announce)
            Quickshell.execDetached(["notify-send", "Wallpaper", root.basename(pick), "-h", "string:x-dunst-stack-tag:wallpaper"]);

        return true;
    }

    function random(announce) {
        if (root.pickRandom(announce))
            return;

        // Nothing listed yet, which means the shell has only just loaded and
        // the `find` above has not come back. One retry rather than a loop: if
        // the folder really is empty there is nothing to be done, and a keybind
        // that keeps asking would be worse than one that quietly did nothing.
        retry.announce = announce;
        root.refresh();
        retry.restart();
    }

    Timer {
        id: retry

        property bool announce: true

        interval: 400

        onTriggered: root.pickRandom(retry.announce)
    }

    // Listed at load rather than waiting for the first open, so SUPER+SHIFT+W
    // works without the picker ever having been opened. This runs at shell
    // startup because the window in shell.qml binds to `open` -- a service
    // singleton is built on first reference, and nothing here would build this
    // one otherwise.
    Component.onCompleted: root.refresh()
}
