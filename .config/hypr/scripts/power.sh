#!/bin/bash
#  ____
# |  _ \ _____      _____ _ __
# | |_) / _ \ \ /\ / / _ \ '__|
# |  __/ (_) \ V  V /  __/ |
# |_|   \___/ \_/\_/ \___|_|
#
# What each session action actually does. Called by the Quickshell power menu
# (services/Power.qml), which replaced wleave -- and by wlogout before that, so
# these words have outlived two menus. That is the reason this is still a script
# rather than six execDetached calls in QML: the menu is the part that keeps
# getting rewritten.
#
# The sleeps are wleave's `delay-command-ms` in another form -- a moment for the
# menu surface to actually go away before the session is torn down underneath
# it. Power.qml waits too, so these are belt and braces for anything calling the
# script directly.

case "$1" in

exit)
    echo ":: Exit"
    sleep 0.5
    # `killall -9 Hyprland`, and not `hyprctl dispatch exit`, on purpose. Since
    # the Hyprland config moved to Lua, hyprctl parses its argument as Lua and
    # the plain `exit` dispatcher fails *silently* -- the menu appears to do
    # nothing. The working polite forms, kept here so they are not rediscovered
    # a third time:
    #
    #     hyprctl dispatch 'hl.dsp.exit()'
    #     loginctl terminate-user "$USER"
    killall -9 Hyprland
    sleep 2
    ;;

lock)
    echo ":: Lock"
    sleep 0.5
    hyprlock
    ;;

reboot)
    echo ":: Reboot"
    sleep 0.5
    systemctl reboot
    ;;

shutdown)
    echo ":: Shutdown"
    sleep 0.5
    systemctl poweroff
    ;;

suspend)
    echo ":: Suspend"
    sleep 0.5
    systemctl suspend
    ;;

hibernate)
    echo ":: Hibernate"
    sleep 1
    systemctl hibernate
    ;;

*)
    echo "Usage: $0 exit|lock|reboot|shutdown|suspend|hibernate" >&2
    exit 1
    ;;

esac
