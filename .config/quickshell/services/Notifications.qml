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
            root.remember(notification);
        }
    }

    // ------------------------------------------------------------------
    // History
    //
    // dunst had this and Quickshell did not: once a card expired the message
    // was gone, which makes every notification a thing you have to read within
    // six seconds or lose. That is fine for "wallpaper effect applied" and
    // useless for anything that arrived while you were in another room.
    //
    // Entries are snapshots taken on arrival, not references to the live
    // notification. They have to be: dismissing a notification destroys the
    // object, so a history of references would be a history of holes. Taking
    // the copy on arrival rather than on dismissal also means an entry exists
    // for notifications that are still on screen, which is what makes the
    // panel a complete record rather than an archive with a gap at the front.
    //
    // In memory only, like dunst's. Persisting it would mean deciding how long
    // a notification stays interesting across a reboot, and the answer is
    // "it doesn't".
    // ------------------------------------------------------------------

    readonly property int historyLength: 100

    // Newest first, so the panel reads top-down without reversing anything.
    property var history: []

    // Entries need a key that survives the array being rebuilt, and the D-Bus
    // id is reused by the server as soon as a notification closes.
    property int nextKey: 1

    // The pill's badge: entries newer than the last time the panel was opened.
    //
    // Derived from the history rather than counted on arrival, so the number
    // can never disagree with the rows behind it. Counting arrivals looks
    // equivalent and is not: a stack-tagged notification replaces its
    // predecessor, so five rows would sit behind a badge reading six, and one
    // of the six would be a message no longer anywhere on the machine.
    property int lastReadKey: 0

    readonly property int unread: root.history.filter(e => e.key > root.lastReadKey).length

    function remember(notification) {
        // The spec's `transient` hint means "show this, do not keep it" --
        // progress bars and volume OSDs set it precisely so they do not silt
        // up a history like this one.
        if (notification.transient)
            return;

        const tag = notification.hints ? notification.hints["x-dunst-stack-tag"] : undefined;

        const entry = {
            key: root.nextKey++,
            appName: notification.appName,
            summary: notification.summary,
            body: notification.body,
            icon: root.stableIcon(notification),
            critical: notification.urgency === NotificationUrgency.Critical,
            time: Date.now(),
            tag: tag || ""
        };

        // A stack tag replaces its predecessor here as well as on screen.
        // Without it, a wallpaper cycle that collapses to one card on screen
        // still leaves twenty identical rows in the history behind it.
        const kept = tag ? root.history.filter(e => e.tag !== tag) : root.history;

        root.history = [entry].concat(kept).slice(0, root.historyLength);
    }

    // An icon reference that will still resolve after the notification itself
    // has been destroyed.
    //
    // Where that reference comes from is not obvious: Quickshell folds a
    // sender's `app_icon` into `image` as `image://icon/<name>` and leaves
    // `appIcon` **empty**, so `notify-send -i firefox` arrives with an empty
    // appIcon and an image that is a theme lookup rather than a picture. Only
    // pixmap-backed images -- the ones a sender pushed as raw data over the
    // bus -- die with their notification, so those are the only ones worth
    // refusing here. A theme lookup by name outlives anything.
    function stableIcon(notification) {
        const image = notification.image;

        if (image.startsWith("image://icon/") || image.startsWith("file:"))
            return image;
        if (image.startsWith("/"))
            return `file://${image}`;

        // Some other `image://` scheme: pixmap data the notification owns, so
        // it is about to become a broken image. Fall back to the application
        // icon if one was named separately.
        if (image !== "" && !image.startsWith("image://"))
            return image;

        return notification.appIcon !== "" ? `image://icon/${notification.appIcon}` : "";
    }

    function forget(key) {
        root.history = root.history.filter(e => e.key !== key);
    }

    function clearHistory() {
        root.history = [];
    }

    function markRead() {
        root.lastReadKey = root.nextKey - 1;
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
