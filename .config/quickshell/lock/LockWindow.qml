// The session lock itself: one surface per output, all input routed to it by
// the compositor.
//
// This is thin on purpose. Everything that can go wrong lives in
// services/Lock.qml (the PAM conversation, and the note on how to get back in
// if this wedges); everything you look at lives in LockSurface.qml. What is
// left here is the wiring between them.
//
// Note there is no keyboardFocus setting to make, unlike every other overlay in
// this config. Under ext-session-lock the compositor hands the lock surfaces
// all input by protocol -- that is the entire point of the protocol -- so the
// exclusive-grab dance the power menu and the pickers have to do does not
// apply, and neither does its consequence: Hyprland's own binds are already
// suppressed while a lock is up.

import QtQuick
import Quickshell.Wayland
import "root:/services"

WlSessionLock {
    id: lock

    locked: Lock.locked

    WlSessionLockSurface {
        id: lockSurface

        // Painted before the picture decodes. A lock surface must never be
        // transparent -- there is nothing behind it but the session it is
        // hiding.
        color: "black"

        LockSurface {
            id: surface

            anchors.fill: parent

            // Each output gets its own picture, chosen for its shape. `screen`
            // is null for a moment while the surface is being set up, hence the
            // guard -- reading `.name` off it unguarded throws during that
            // frame and the binding never re-evaluates.
            wallpaper: Lock.wallpaperFor(lockSurface.screen ? lockSurface.screen.name : "")
            placement: Lock.placement
            blurAmount: Lock.blurAmount
            pixelRatio: lockSurface.screen ? lockSurface.screen.devicePixelRatio : 1
            scrimStrength: Lock.scrimStrength

            capsLock: Lock.capsLock
            onActivity: Lock.noteActivity()

            busy: Lock.busy
            status: Lock.status
            statusIsError: Lock.statusIsError

            onSubmitted: Lock.submit(surface.password)

            // Cleared centrally rather than by each surface deciding for
            // itself: with three outputs there are three of these, and a failed
            // attempt has to empty all of them, not just the one being typed
            // into.
            Connections {
                target: Lock

                function onCleared() {
                    surface.password = "";
                }
            }
        }
    }
}
