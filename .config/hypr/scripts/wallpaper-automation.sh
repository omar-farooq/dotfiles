#!/bin/bash
#     _         _         __        ______  
#    / \  _   _| |_ ___   \ \      / /  _ \ 
#   / _ \| | | | __/ _ \   \ \ /\ / /| |_) |
#  / ___ \ |_| | || (_) |   \ V  V / |  __/ 
# /_/   \_\__,_|\__\___/     \_/\_/  |_|    
#                                          

sec=$(cat ~/.config/ml4w/settings/wallpaper-automation.sh)

# The "am I already running" flag lives in the runtime dir, not in
# ml4w/cache/. It is a lock, not a setting: a reboot should clear it, and
# leaving it under a directory that gets wiped wholesale would have the toggle
# come back believing it was off while the loop was still going. $XDG_RUNTIME_DIR
# is tmpfs and cleared at logout, which is exactly the lifetime this wants.
flag="${XDG_RUNTIME_DIR:-/tmp}/wallpaper-automation"
_setWallpaperRandomly() {
    # Was `waypaper --random`. The shell picks now, so this loop and the
    # SUPER+SHIFT+W keybind can no longer disagree about the folder.
    #
    # Silent rather than the keybind's `random`: that one puts up a card naming
    # the new wallpaper, which here would be a notification every $sec seconds
    # for as long as the loop runs.
    qs ipc call wallpaper randomSilent
    echo ":: Next wallpaper in 60 seconds..."
    sleep $sec
    _setWallpaperRandomly
}

if [ ! -f "$flag" ] ;then
    touch "$flag"
    echo ":: Start wallpaper automation script"
    notify-send "Wallpaper automation process started" "Wallpaper will be changed every $sec seconds."
    _setWallpaperRandomly
else
    rm "$flag"
    notify-send "Wallpaper automation process stopped."
    echo ":: Wallpaper automation script process $wp stopped"
    wp=$(pgrep -f wallpaper-automation.sh)
    kill -KILL $wp
fi