// Renders lock/LockSurface.qml full-screen in an ordinary layer surface so it
// can be looked at, and photographed with grim, without ever taking a real
// session lock.
//
// Kept rather than deleted, unlike the other probes written during the
// migration. The lock surface is the one component in this config that cannot
// be inspected while it is doing its job -- by the time you can see it, it has
// the keyboard and the whole screen -- so the only way to iterate on it is to
// render it somewhere else. Every value it takes is an environment variable so
// a state can be summoned without editing anything:
//
//   MOCK_SCREEN   output to open on (default DP-1; probes land on DP-3 if left
//                 to themselves, which reads as the probe having failed)
//   MOCK_PAPER    absolute path to a picture
//   MOCK_BLUR     blurMax, 0 for none
//   MOCK_SCRIM    0..1
//   MOCK_PLACE    center | corner
//   MOCK_DOTS     how many characters to look typed
//   MOCK_CAPS     1 to show the Caps Lock warning
//   MOCK_BUSY     1 for the "Checking..." state
//   MOCK_STATUS   status line text
//   MOCK_ERROR    1 to draw that status as a failure
//
//   MOCK_PAPER=~/Pictures/wallpaper5.jpg MOCK_PLACE=corner MOCK_SCRIM=0.4 \
//   MOCK_DOTS=8 qs -p ~/.config/quickshell/lockmockup.probe.qml
//
// Must live at the top level of ~/.config/quickshell: `qs -p <file>` resolves
// `root:/` to the directory holding the file it was given, so a probe in a
// subdirectory cannot import root:/theme -- Quickshell refuses module paths
// outside the config folder outright.
//
// Takes no keyboard focus on purpose. Omar is usually at the machine while this
// runs, and a probe that grabbed the keyboard would swallow his typing.

import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/lock"

ShellRoot {
    PanelWindow {
        id: win

        // A probe window does not land on the focused monitor -- it goes to
        // DP-3 -- so the output is always named rather than left to chance.
        screen: {
            const want = Quickshell.env("MOCK_SCREEN") || "DP-1";
            return Quickshell.screens.find(s => s.name === want) || Quickshell.screens[0];
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-lockmockup"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusiveZone: 0
        color: "transparent"

        LockSurface {
            anchors.fill: parent

            acceptInput: false
            forceFocusRing: true

            wallpaper: Quickshell.env("MOCK_PAPER") || ""
            blurAmount: parseFloat(Quickshell.env("MOCK_BLUR") || "0")
            scrimStrength: parseFloat(Quickshell.env("MOCK_SCRIM") || "0.55")
            placement: Quickshell.env("MOCK_PLACE") || "center"
            pixelRatio: win.screen ? win.screen.devicePixelRatio : 1

            // A run of dots of a given length, since there is no typing here.
            password: "x".repeat(parseInt(Quickshell.env("MOCK_DOTS") || "0", 10))

            capsLock: Quickshell.env("MOCK_CAPS") === "1"

            busy: Quickshell.env("MOCK_BUSY") === "1"
            status: Quickshell.env("MOCK_STATUS") || ""
            statusIsError: Quickshell.env("MOCK_ERROR") === "1"
        }
    }
}
