pragma Singleton

// Which MPRIS player the media keys and the bar pill act on, and the four
// transport actions themselves.
//
// This replaces `playerctl --player=spotify,%any` in the XF86Audio* binds.
// Quickshell already spoke MPRIS for the bar pill, so playerctl was a second,
// entirely separate implementation of the same preference rule -- and the only
// remaining reason the package was installed. The keys now come back in through
// `qs ipc call media <action>` and land on this file, the same one MediaPill
// reads, so the two can no longer disagree about which player is "the" player.
//
// The trade this makes: with playerctl the keys worked whether or not the shell
// was up. Now they need the shell running. That is the same bet the rest of the
// desktop already makes -- the bar, the launcher and the clipboard picker all
// die with it.

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property string preferredName: "spotify"

    function matches(player, name) {
        return `${player.dbusName || ""} ${player.identity || ""}`.toLowerCase().includes(name);
    }

    // Spotify, or null. MediaPill shows this one and nothing else: widening it
    // to "whatever is playing" means every YouTube tab takes over the pill.
    readonly property var preferred: Mpris.players.values.find(p => root.matches(p, root.preferredName)) || null

    // What the *keys* act on, which is a looser question than what the pill
    // shows. This is `spotify,%any`: Spotify wins whenever it is running, even
    // paused, and otherwise the keys fall to another player rather than going
    // dead. Among the others, one that is actually playing beats one that is
    // not, since that is the thing the user is reaching for the key about.
    readonly property var active: {
        if (root.preferred)
            return root.preferred;

        const others = Mpris.players.values.filter(p => p.canControl);
        return others.find(p => p.isPlaying) || others[0] || null;
    }

    // Each action checks its own capability flag rather than a blanket
    // canControl: a player can accept next/previous while refusing pause, and
    // calling an unsupported method is a D-Bus error rather than a no-op.
    function playpause() {
        if (root.active && root.active.canTogglePlaying)
            root.active.togglePlaying();
    }

    function pause() {
        if (root.active && root.active.canPause)
            root.active.pause();
    }

    function next() {
        if (root.active && root.active.canGoNext)
            root.active.next();
    }

    function previous() {
        if (root.active && root.active.canGoPrevious)
            root.active.previous();
    }

    function raise() {
        if (root.active && root.active.canRaise)
            root.active.raise();
    }
}
