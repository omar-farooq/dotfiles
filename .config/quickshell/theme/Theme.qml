pragma Singleton

// Every colour, size and font the bar uses. One file, so re-shaping the bar is
// one edit rather than a sweep through two dozen CSS blocks.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // -----------------------------------------------------------------
    // Palette
    //
    // pywal rewrites ~/.cache/wal/colors-hyprland.conf on every wallpaper
    // change. conf/colors.lua already parses that same file for Hyprland's
    // window borders -- reading it here too, rather than keeping a second copy
    // of the palette, is what stops the bar and the borders drifting apart.
    //
    // FileView watches the file, so changing wallpaper recolours the bar in
    // place. Under waybar this needed a full restart of the bar, because GTK
    // only read the imported CSS at startup.
    // -----------------------------------------------------------------

    // Seeded with the current palette rather than left empty. pywal may not have
    // run yet on a fresh machine, and an undefined colour doesn't fail locally
    // -- it breaks every binding downstream of it.
    property var wal: ({
        background: "#110f1e",
        foreground: "#78ddea",
        color5: "#5BA5B8",
        color11: "#5A6592"
    })

    FileView {
        id: paletteFile

        path: `${Quickshell.env("HOME")}/.cache/wal/colors-hyprland.conf`
        preload: true
        watchChanges: true

        onFileChanged: reload()
        // Merged over the defaults instead of replacing them, so a truncated or
        // half-written file (pywal is not atomic) can't blank the whole bar.
        onLoaded: root.wal = Object.assign({}, root.wal, root.parsePalette(paletteFile.text()))
    }

    // `$color11 = rgb(5A6592)` -> { color11: "#5A6592" }
    function parsePalette(text) {
        const out = {};
        for (const line of text.split("\n")) {
            const m = /^\s*\$(\w+)\s*=\s*rgb\(([0-9a-fA-F]{6})\)\s*$/.exec(line);
            if (m)
                out[m[1]] = "#" + m[2];
        }
        return out;
    }

    // -----------------------------------------------------------------
    // Semantic roles
    //
    // The role -> pywal slot mapping is carried over verbatim from the old
    // themes/ml4w/colored/style.css, so the bar keeps the same relationship to
    // a given wallpaper that it had under waybar.
    // -----------------------------------------------------------------

    readonly property color surface: wal.color5         // ordinary pills
    readonly property color surfaceStrong: wal.color11  // pills that should read as anchors
    readonly property color background: wal.background  // panels large enough to need a ground
    readonly property color text: "#FFFFFF"
    readonly property color danger: "#DC2F2F"
    readonly property color warning: "#FF9A3C"

    // -----------------------------------------------------------------
    // Metrics
    // -----------------------------------------------------------------

    readonly property int barHeight: 34
    readonly property int barMarginTop: 8
    readonly property int barMarginSide: 12

    readonly property int pillHeight: 26
    readonly property int pillPadding: 11
    readonly property real pillOpacity: 0.85

    // Gap between pills. Also the gap between workspace buttons, halved.
    readonly property int gap: 8

    readonly property int animation: 150

    // -----------------------------------------------------------------
    // Fonts
    //
    // One family each, not a list: QML's `font` value type exposes `family`
    // but not `families`, so the waybar CSS trick of naming four fonts and
    // letting the toolkit pick per glyph isn't available here. Qt still falls
    // back through fontconfig for codepoints the named family lacks, which is
    // what lets a Brands glyph appear in a Text asking for Free Solid -- but
    // words and glyphs are kept in separate Text items (BarText vs BarIcon) so
    // the common case never depends on that fallback.
    // -----------------------------------------------------------------

    readonly property string textFont: "Fira Sans"
    readonly property string iconFont: "Font Awesome 7 Free Solid"

    readonly property int fontSize: 13
    readonly property int iconSize: 14
}
