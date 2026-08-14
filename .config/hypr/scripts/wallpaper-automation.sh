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
    waypaper --random
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