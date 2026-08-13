pragma Singleton

// Every glyph the bar draws, in one table.
//
// Written as \u escapes rather than pasted characters: Font Awesome codepoints
// live in the Unicode private use area, so pasted they show as tofu in most
// editors and in `git diff`, and a careless copy silently drops them. Named
// here once, nothing else in the tree has to contain a glyph.
//
// Codepoints carried over verbatim from the old waybar modules.json.

import Quickshell

Singleton {
    // Power menu
    readonly property string power: "\uf011"

    // Tools drawer
    readonly property string tools: "\uf5fd"
    readonly property string clipboard: "\uf0ea"
    readonly property string shader: "\ue4dc"
    readonly property string wallpaper: "\uf03e"

    // hypridle. A closed padlock while idle-locking is armed, an open one when
    // it has been switched off -- waybar only ever drew the closed padlock and
    // recoloured it red, which reads as "broken" rather than "off".
    readonly property string idleOn: "\uf023"
    readonly property string idleOff: "\uf09c"

    // Hardware drawer
    readonly property string system: "\ue473"

    // Updates
    readonly property string updates: "\uf0ab"

    // Network
    readonly property string wifi: "\uf1eb"
    readonly property string ethernet: "\uf796"

    // Audio. volumeLevels is waybar's low/medium/high triple, indexed by
    // volume; the others key off the sink's port type.
    readonly property string volumeMuted: "\uf6a9"
    readonly property var volumeLevels: ["\uf026", "\uf028", "\uf028"]
    readonly property string headphone: "\uf025"
    readonly property string headset: "\uf590"
    readonly property string phone: "\uf095"
    readonly property string car: "\uf1b9"
    // Media. The Spotify mark is the same codepoint the workspace pills use for
    // a Spotify window, which is deliberate -- one app, one glyph.
    readonly property string spotify: "\uf1bc"
    readonly property string play: "\uf04b"
    readonly property string pause: "\uf04c"
    // Launcher
    readonly property string search: "\uf002"
}
