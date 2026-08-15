pragma Singleton

// Which MPRIS player the media keys and the bar pill act on, and the four
// transport actions themselves.
//
// This replaces `playerctl --player=spotify,%any` in the XF86Audio* binds.
// Quickshell already spoke MPRIS for the bar pill, so playerctl was a second,
// entirely separate implementation of the same preference rule -- and the only
// remaining reason the package was installed. The keys now come back in through
// `qs ipc call media <action>` and land on this file, the same one SpotifyPill
// reads, so the two can no longer disagree about which player is "the" player.
//
// The trade this makes: with playerctl the keys worked whether or not the shell
// was up. Now they need the shell running. That is the same bet the rest of the
// desktop already makes -- the bar, the launcher and the clipboard picker all
// die with it.

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray

Singleton {
    id: root

    readonly property string preferredName: "spotify"

    function matches(player, name) {
        return `${player.dbusName || ""} ${player.identity || ""}`.toLowerCase().includes(name);
    }

    // Spotify, or null. SpotifyPill shows this one and nothing else: widening it
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

    // Spotify's tray item, when it has registered one.
    //
    // The pill hosts this instead of the tray row: one application at both ends
    // of the bar was the mess this removes, and of the two the pill is by far
    // the richer. TrayRow filters out whatever this points at.
    //
    // Rehoming the *menu* is the whole point. Spotify's indicator implements no
    // `Activate` handler at all -- calling it answers "No handler for Activate"
    // -- so minimise-to-tray and Quit exist nowhere except inside that menu.
    // Hiding the icon without moving the menu somewhere would have quietly
    // deleted both.
    readonly property var trayItem: SystemTray.items.values.find(item => root.matchesTray(item)) || null

    function matchesTray(item) {
        return `${item.id} ${item.title}`.toLowerCase().includes(root.preferredName);
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

    // Seeking, and the two playback modes -- all three only reachable from the
    // popout, since a pill has no room for them and the media keys have no
    // spare key. Same capability-checked shape as the transport actions above.
    //
    // `position` is writable and seeks when written, which is the absolute form
    // MprisPlayer also offers a relative `seek(offset)` for. Absolute is what a
    // scrubbed progress bar produces.
    function seek(seconds) {
        if (root.active && root.active.canSeek)
            root.active.position = seconds;
    }

    function toggleShuffle() {
        if (root.active && root.active.shuffleSupported)
            root.active.shuffle = !root.active.shuffle;
    }

    // Off, then the whole playlist, then the one track -- Spotify's own order,
    // so the button walks through the states in the order its UI trained you
    // to expect.
    function cycleLoop() {
        if (!root.active || !root.active.loopSupported)
            return;

        const order = [MprisLoopState.None, MprisLoopState.Playlist, MprisLoopState.Track];
        root.active.loopState = order[(order.indexOf(root.active.loopState) + 1) % order.length];
    }
}
