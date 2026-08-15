#!/bin/bash
#  ____  _                             _     
# |  _ \(_) __ _  __ _ _ __   ___  ___(_)___ 
# | | | | |/ _` |/ _` | '_ \ / _ \/ __| / __|
# | |_| | | (_| | (_| | | | | (_) \__ \ \__ \
# |____/|_|\__,_|\__, |_| |_|\___/|___/_|___/
#                |___/                       
# 

clear
sleep 0.5
figlet "Diagnosis"
echo
echo "This script will check that essential packages and "
echo "execution commands are available on your system."
echo

_commandExists() {
    package="$1";
    if ! type $package > /dev/null 2>&1; then
        echo ":: ERROR: $package doesn't exists. Please install it with yay -S $2"
    else
        echo ":: OK: $package found."
    fi
}

_folderExists() {
    folder="$1";
    if [ ! -d $folder ]; then
        echo ":: ERROR: $folder doesn't exists."
    else
        echo ":: OK: $folder found."
    fi
}

# rofi and dunst are deliberately absent -- Quickshell absorbed everything
# they did (pickers, notifications), so do not check for them here.
_commandExists "notify-send" "libnotify"
_commandExists "qs" "quickshell"
_commandExists "hyprpaper" "hyprpaper"
# Still checked, but no longer the lock screen -- Quickshell's replaced it.
# hyprlock is kept installed as the rescue path for a shell that wedges while
# holding the session lock; services/Lock.qml spells out how to use it.
_commandExists "hyprlock" "hyprlock"
_commandExists "hypridle" "hypridle"
_commandExists "hyprshade" "hyprshade"
_commandExists "wal" "python-pywal"
_commandExists "gum" "gum"
_commandExists "magick" "imagemagick"
_commandExists "figlet" "figlet"
_commandExists "waypaper" "waypaper"

echo
echo "Press return to exit"
read