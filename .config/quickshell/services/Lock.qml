pragma Singleton

// The lock screen's state, and the PAM conversation behind it.
//
// Split from the surface that draws it (lock/LockSurface.qml) and from the
// session lock that hosts it (lock/LockWindow.qml) for the same reason the
// power menu is split from power.sh: this is the part with the sharp edges, and
// it should be readable without wading through layout.
//
// SAFETY, because this is the one component in the config that can lock Omar
// out of his own machine:
//
//   * hyprlock is deliberately still installed. If this ever wedges, the way
//     back in is a TTY (ctrl+alt+F2), then:
//
//         XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 hyprlock
//
//     A second session-lock client can take over from a dead one and unlock
//     normally, which keeps every window. `killall -9 Hyprland` is the blunt
//     fallback and drops back to sddm, losing the session.
//
//   * The shell process holds the lock. If it dies while locked, the compositor
//     keeps the screen locked -- that is the ext-session-lock protocol working
//     as designed, not a bug. Hence the rescue path above.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

Singleton {
    id: root

    // -----------------------------------------------------------------
    // Settings
    //
    // The lock screen's own picture, deliberately NOT the desktop wallpaper --
    // seeing it through the lock spends it, so unlocking would reveal nothing.
    // This is the one place it is set.
    // -----------------------------------------------------------------

    // One per output, keyed by monitor name. Not only for variety: the three
    // screens are not the same shape, and a single picture always loses on two
    // of them. DP-1 is 2.39:1 and DP-3/HDMI-A-1 are 16:9, so an image chosen for
    // one gets cropped on the others -- wallpaper5 is 2.22:1 and belongs on the
    // ultrawide; the panels take 16:9 images. Note wallpaper1 is only 1920x1080,
    // so on DP-3 (3840x2160 physical) it is upscaled 2x -- chosen for the art
    // over the pixels, which is a real trade rather than an oversight.
    //
    // `hyprctl monitors -j` gives the names if a screen is ever added.
    readonly property var wallpapers: ({
        "DP-1": `${root.pictures}/wallpaper5.jpg`,
        "DP-3": `${root.pictures}/wallpaper1.jpg`,
        "HDMI-A-1": `${root.pictures}/wallpaper4.jpg`
    })

    // For an output not in the map -- a screen plugged in later, or one renamed
    // by a cable swap. Better a picture that crops than a lock screen that is
    // flat black and looks broken.
    readonly property string wallpaperFallback: `${root.pictures}/wallpaper5.jpg`

    readonly property string pictures: `${Quickshell.env("HOME")}/Pictures`

    function wallpaperFor(name) {
        return root.wallpapers[name] || root.wallpaperFallback;
    }

    // "corner" keeps the middle of the picture clear. Every candidate wallpaper
    // except this one is a centred portrait, where "center" put the card on the
    // subject's chest; this one is a landscape and would take either.
    readonly property string placement: "corner"

    // Softening rather than concealment -- the picture was chosen, so hiding it
    // would defeat the point. Legibility comes from the scrim instead.
    readonly property real blurAmount: 4
    readonly property real scrimStrength: 0.40

    // -----------------------------------------------------------------
    // State
    // -----------------------------------------------------------------

    property bool locked: false

    // True from the moment a password is submitted until PAM answers. The field
    // is disabled meanwhile, because PAM's failure delay is measured in seconds
    // and a field that still accepts typing during it looks broken.
    property bool busy: false

    property string status: ""
    property bool statusIsError: false

    property int attempts: 0

    // Held only between submit and PAM asking for it, then cleared. Deliberately
    // not a property the surface binds to.
    property string pending: ""

    function lock() {
        if (root.locked)
            return;

        root.attempts = 0;
        root.status = "";
        root.statusIsError = false;
        root.busy = false;
        root.locked = true;

        // One read as the screen appears, so the warning is already correct
        // before a single key is pressed.
        root.noteActivity();
    }

    function submit(password) {
        if (root.busy || !root.locked)
            return;

        // An empty submit is a stray Return, not an attempt. PAM would count it
        // against the retry limit, which is a real way to lock yourself out by
        // leaning on the keyboard.
        if (password === "")
            return;

        root.pending = password;
        root.busy = true;
        root.status = "";
        root.statusIsError = false;

        if (!pam.start()) {
            root.busy = false;
            root.pending = "";
            root.fail("Could not start authentication — use a TTY");
        }
    }

    function fail(message) {
        root.status = message;
        root.statusIsError = true;
    }

    // Emitted whenever every surface should empty its field -- on a failed
    // attempt and on a successful one. Central rather than per-surface because
    // there is one of these per output.
    signal cleared

    // -----------------------------------------------------------------
    // Caps Lock
    //
    // Worth the trouble because of pam_faillock: /etc/pam.d/system-auth allows
    // three failures before a ten minute lockout, and because `login` includes
    // the same stack that lockout also blocks the TTY rescue and hyprlock. Caps
    // Lock is the single likeliest way to burn all three attempts without ever
    // realising why, so the warning is a safety feature rather than a nicety.
    //
    // hyprctl is the only source: Quickshell exposes no keyboard LED state and
    // QML cannot query Caps Lock at all.
    // -----------------------------------------------------------------

    property bool capsLock: false

    // Polled, but only in bursts. A lock screen can sit untouched for hours and
    // a background poll would spawn a process every half second the whole time,
    // on a machine that is otherwise completely idle -- which is exactly when it
    // should be quietest. So the timer only runs while somebody is demonstrably
    // there: it starts on any keystroke (including the Caps Lock key itself,
    // which produces a key event even though it produces no character) and
    // stops again once the keyboard has been quiet for a few seconds.
    property bool capsWatch: false

    function noteActivity() {
        root.capsWatch = true;
        capsIdle.restart();
        root.pollCaps();
    }

    function pollCaps() {
        if (!capsProc.running)
            capsProc.running = true;
    }

    Timer {
        id: capsIdle

        interval: 6000
        onTriggered: root.capsWatch = false
    }

    Timer {
        running: root.locked && root.capsWatch
        interval: 400
        repeat: true
        onTriggered: root.pollCaps()
    }

    Process {
        id: capsProc

        command: ["hyprctl", "-j", "devices"]

        stdout: StdioCollector {
            onStreamFinished: {
                // `main` marks the real keyboard; the same list also carries
                // power buttons and a pair of speakers, all of which report a
                // capsLock of their own and would otherwise vote.
                try {
                    const keyboards = (JSON.parse(text).keyboards) || [];
                    const main = keyboards.find(k => k.main) || keyboards[0];
                    root.capsLock = !!(main && main.capsLock);
                } catch (e) {
                    // A malformed read should not clear a true warning.
                }
            }
        }
    }

    PamContext {
        id: pam

        // /etc/pam.d/hyprlock, which already exists and is a one-liner that
        // includes `login`. Reusing it rather than installing another file
        // keeps this from needing root to set up, and means the lock screen
        // authenticates exactly the way the one it replaces did.
        config: "hyprlock"

        onPamMessage: {
            if (pam.responseRequired)
                pam.respond(root.pending);
        }

        onCompleted: result => {
            root.busy = false;
            root.pending = "";

            if (result === PamResult.Success) {
                root.locked = false;
                root.status = "";
                root.statusIsError = false;
                root.attempts = 0;
                root.cleared();
                return;
            }

            root.attempts += 1;
            root.cleared();

            if (result === PamResult.MaxTries)
                root.fail("Too many attempts — authentication locked out");
            else if (result === PamResult.Error)
                root.fail("Authentication error — use a TTY");
            else
                root.fail(root.attempts === 1 ? "Incorrect password" : `Incorrect password — ${root.attempts} attempts`);
        }

        onError: error => {
            root.busy = false;
            root.pending = "";
            root.cleared();
            root.fail(`Authentication error (${PamError.toString(error)}) — use a TTY`);
        }
    }
}
