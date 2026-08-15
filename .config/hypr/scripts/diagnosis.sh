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

# rofi, dunst and waypaper are deliberately absent -- Quickshell absorbed
# everything they did (pickers, notifications, the wallpaper chooser), so do not
# check for them here.
_commandExists "notify-send" "libnotify"
_commandExists "qs" "quickshell"
_commandExists "hyprpaper" "hyprpaper"
# Still checked, but no longer the lock screen -- Quickshell's replaced it.
# hyprlock is kept installed as the rescue path for a shell that wedges while
# holding the session lock; services/Lock.qml spells out how to use it.
_commandExists "hyprlock" "hyprlock"
_commandExists "hypridle" "hypridle"
# hyprshade is deliberately absent: the screen shader was retired on 2026-08-16
# because it flickers DP-3 and Hyprland's shader is session-global. The package
# may still be installed, but nothing here calls it -- see conf/keybindings.
_commandExists "wal" "python-pywal"
_commandExists "magick" "imagemagick"
# Only this script's own banner needs figlet now -- the two ml4w scripts that
# used it are gone. Kept because a failing banner is the first thing you would
# see when running this.
_commandExists "figlet" "figlet"
# gum was checked here for ml4w's snapshot.sh (timeshift prompts), which was
# deleted along with the rest of ml4w. Nothing on the machine calls it now.

echo
echo "Press return to exit"
read