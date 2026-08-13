// Root of the Quickshell config -- the replacement for waybar and the ml4w
// theme machinery that wrapped it.
//
// Run it with a bare `qs` (this lives at ~/.config/quickshell, which is the
// default config path). To try a change without disturbing the running bar,
// `qs -p .` from this directory starts a second, independent instance.
//
// Quickshell watches these files and hot-reloads on save, so editing a module
// takes effect immediately -- there is no launch script to re-run.

import Quickshell
import Quickshell.Io
import "root:/bar"

ShellRoot {
    id: root

    property bool barVisible: true

    // Reached from the keybinds as `qs ipc call bar toggle`.
    //
    // waybar's toggle.sh had to kill the process and drop a marker file that
    // launch.sh checked on next startup, because there was no way to talk to a
    // running bar. Here it is a property, so the bar comes back in the state it
    // left rather than being rebuilt from scratch.
    IpcHandler {
        target: "bar"

        function toggle(): void {
            root.barVisible = !root.barVisible;
        }

        function show(): void {
            root.barVisible = true;
        }

        function hide(): void {
            root.barVisible = false;
        }

        function reload(): void {
            Quickshell.reload(true);
        }
    }

    // One bar per monitor. Variants rebuilds this list as screens come and go,
    // so plugging the TV back in gets a bar without a reload -- and each Bar is
    // handed its own `modelData` screen, which is what lets the workspace row
    // narrow itself to the workspaces living on that one output.
    Variants {
        model: Quickshell.screens

        Bar {
            visible: root.barVisible
        }
    }
}
