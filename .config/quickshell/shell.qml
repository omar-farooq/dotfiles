//@ pragma UseQApplication

// Root of the Quickshell config -- the replacement for waybar and the ml4w
// theme machinery that wrapped it.
//
// QApplication mode is required for the system tray: right-clicking a tray icon
// asks the owning application to draw its own menu, and that goes through Qt's
// platform menu support, which only exists under QApplication. Without the
// pragma the icons appear and left-click works, but every context menu fails.
// Changing this line needs a real restart -- a hot reload will not pick it up.
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
import "root:/components"
import "root:/notifications"
import "root:/launcher"
import "root:/clipboard"
import "root:/keybinds"
import "root:/wallpaper"
import "root:/power"
import "root:/lock"
import "root:/services"

ShellRoot {
    id: root

    property bool barVisible: true

    // Reached from the keybinds as `qs ipc call bar toggle`.
    //
    // waybar's toggle.sh had to kill the process and drop a marker file that
    // launch.sh checked on next startup, because there was no way to talk to a
    // running bar. Here it is a property, so the bar comes back in the state it
    // left rather than being rebuilt from scratch.
    //
    // Nothing here is called `show` or `hide`: `qs ipc` has its own `show`
    // subcommand, so `qs ipc call bar show` parses ambiguously and silently
    // prints the target listing instead of calling anything.
    IpcHandler {
        target: "bar"

        function toggle(): void {
            root.barVisible = !root.barVisible;
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

    // Also one per monitor: a click on any screen should dismiss a popout open
    // on any other, so each output needs its own catcher. See PopoutCatcher --
    // it only exists while something is open.
    Variants {
        model: Quickshell.screens

        PopoutCatcher {}
    }

    // Not per-screen: notifications land on one fixed output, the way dunst was
    // configured. See NotificationOverlay.
    NotificationOverlay {}

    // One of each, moved to whichever screen has focus when they open.
    LauncherWindow {}

    ClipboardWindow {}

    KeybindsWindow {}

    EffectsWindow {}

    PowerWindow {}

    // Not per-screen and not a Variants: WlSessionLock builds its own surface on
    // every output, because the protocol requires every output to be covered
    // before the compositor considers the session locked.
    //
    // Inert until Lock.locked goes true. It replaces hyprlock, which is
    // deliberately still installed -- services/Lock.qml has the way back in if
    // this ever wedges.
    LockWindow {}

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            Launcher.toggle();
        }

        function close(): void {
            Launcher.hide();
        }
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            Clipboard.toggle();
        }

        function close(): void {
            Clipboard.hide();
        }
    }

    IpcHandler {
        target: "keybinds"

        function toggle(): void {
            Keybinds.toggle();
        }

        function close(): void {
            Keybinds.hide();
        }
    }

    IpcHandler {
        target: "effects"

        function toggle(): void {
            WallpaperEffects.toggle();
        }

        function close(): void {
            WallpaperEffects.hide();
        }

        function choose(name: string): void {
            WallpaperEffects.apply(name);
        }
    }

    // `qs ipc call lock lock`. Only one direction is exposed on purpose: there
    // is no `unlock` here, because an IPC call that unlocks the screen is a
    // hole straight through the lock -- anything that can reach the socket
    // could open the session.
    IpcHandler {
        target: "lock"

        function lock(): void {
            Lock.lock();
        }
    }

    IpcHandler {
        target: "power"

        function toggle(): void {
            Power.toggle();
        }

        function close(): void {
            Power.hide();
        }
    }

    // The XF86Audio transport keys, which used to be four playerctl calls. See
    // services/Media.qml -- the point of routing them here is that the keys and
    // the bar pill now share one answer to "which player?".
    IpcHandler {
        target: "media"

        function playpause(): void {
            Media.playpause();
        }

        function pause(): void {
            Media.pause();
        }

        function next(): void {
            Media.next();
        }

        function previous(): void {
            Media.previous();
        }
    }
}
