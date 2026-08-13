// The focused window's title, for this bar's monitor.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "root:/theme"
import "root:/components"

Pill {
    id: root

    required property var screen

    // waybar's `separate-outputs`. Each bar names the window focused on its own
    // screen -- not whichever window holds focus globally, which would have all
    // three bars saying the same thing.
    readonly property var toplevel: {
        const mon = Hyprland.monitorFor(root.screen);
        return mon && mon.activeWorkspace ? mon.activeWorkspace.activeToplevel : null;
    }

    readonly property string title: root.toplevel ? root.shorten(root.toplevel.title) : ""

    // An empty pill floating next to the launcher looks like a rendering fault,
    // so on an empty workspace the module goes away entirely.
    visible: root.title !== ""
    interactive: false

    // Trailing site and app noise the browsers and Office web apps append.
    // Carried over from waybar's rewrite table.
    function shorten(title) {
        return (title || "").replace(/ - Brave Search$/, "").replace(/ - Brave$/, "").replace(/ - Chromium$/, "").replace(/ - Outlook$/, "").replace(/ Microsoft Teams$/, "");
    }

    BarText {
        text: root.title
        font.weight: Font.Normal
        elide: Text.ElideRight

        // Capped, so a long document title can't push the centred workspace row
        // off centre. implicitWidth is the untruncated width and does not
        // depend on width, so this is not a binding loop.
        width: Math.min(implicitWidth, 420)
    }
}
