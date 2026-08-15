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

    // Notifications. A bell for the pill, and the same bell with a line
    // through it for a history that has nothing in it -- the empty panel
    // says so in words, but the glyph says it before you read them.
    readonly property string bell: "\uf0f3"
    readonly property string bellQuiet: "\uf1f6"

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

    // Which of the three to draw for a given level. Lives here rather than in
    // the volume pill because the mixer's rows pick their icons the same way,
    // and two copies of the rule would eventually disagree.
    function forVolume(volume, muted) {
        if (muted)
            return volumeMuted;

        const index = Math.min(volumeLevels.length - 1, Math.floor(volume / (100 / volumeLevels.length)));
        return volumeLevels[Math.max(0, index)];
    }

    // Media. The Spotify mark is the same codepoint the workspace pills use for
    // a Spotify window, which is deliberate -- one app, one glyph. It is also
    // the fallback when a track has no art, or has art that has not downloaded
    // yet -- Spotify's art is a URL on their CDN rather than a local file.
    //
    // The transport glyphs are new: waybar's module was a line of text with a
    // click binding, so it had nowhere to draw a button.
    readonly property string stepBack: "\uf048"
    readonly property string stepForward: "\uf051"
    // The player's own menu, hosted on the media panel now that its tray icon
    // is filtered out of the tray row.
    readonly property string more: "\uf141"

    readonly property string shuffle: "\uf074"
    readonly property string repeat: "\uf363"

    readonly property string spotify: "\uf1bc"
    readonly property string play: "\uf04b"
    readonly property string pause: "\uf04c"
    // Launcher. The star marks a pinned application in the browse list.
    readonly property string search: "\uf002"
    readonly property string star: "\uf005"

    // Clipboard
    readonly property string image: "\uf1c5"

    // Calendar popout. Paging arrows either side of the month name.
    readonly property string chevronLeft: "\uf053"
    readonly property string chevronRight: "\uf054"

    // Wallpaper effects. A tick beside the effect currently in force,
    // which the old rofi list had no way to show.
    readonly property string check: "\uf00c"
}
