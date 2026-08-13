pragma Singleton

// The notification daemon.
//
// Replaces dunst. Quickshell owns org.freedesktop.Notifications directly, so
// there is no second process and no second theme to keep in step with the bar
// -- notifications are drawn by the same QML, from the same palette.
//
// Only one daemon can hold that D-Bus name at a time, which is why dunst has to
// be stopped before this can serve anything.

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    // dunst gave every urgency the same six seconds -- critical included -- so
    // this does too, rather than quietly changing how long things linger.
    readonly property int timeout: 6000

    readonly property alias list: server.trackedNotifications

    NotificationServer {
        id: server

        // Advertise only what the cards can actually render, so senders do not
        // hand us markup or actions that get silently dropped.
        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: notification => {
            // Tracking is what keeps the object alive past this handler. An
            // untracked notification is destroyed the moment this returns and
            // never reaches the overlay at all.
            notification.tracked = true;

            root.collapseStackTag(notification);
        }
    }

    // dunst's stack tag: a sender reusing a tag means "replace my previous
    // one". wallpaper.sh leans on this while cycling wallpapers -- without it
    // an automation run leaves one popup per change stacked down the screen.
    function collapseStackTag(notification) {
        const tagOf = n => (n.hints ? n.hints["x-dunst-stack-tag"] : undefined);

        const tag = tagOf(notification);
        if (!tag)
            return;

        // Copied before iterating: dismissing removes entries from the model
        // being walked.
        for (const other of [...server.trackedNotifications.values]) {
            if (other !== notification && tagOf(other) === tag)
                other.dismiss();
        }
    }

    function dismissAll() {
        for (const n of [...server.trackedNotifications.values])
            n.dismiss();
    }
}
