#!/bin/bash
#  _   _                      _               _      
# | | | |_   _ _ __  _ __ ___| |__   __ _  __| | ___ 
# | |_| | | | | '_ \| '__/ __| '_ \ / _` |/ _` |/ _ \
# |  _  | |_| | |_) | |  \__ \ | | | (_| | (_| |  __/
# |_| |_|\__, | .__/|_|  |___/_| |_|\__,_|\__,_|\___|
#        |___/|_|                                    
# 

# `next` advances to the following filter and leaves it selected for the
# toggle below. This replaced a rofi picker: with only three filters installed
# (blue-light-filter, invert-colors, vibrance) a list to choose from was more
# ceremony than the choice deserved, and it was the last thing keeping rofi in
# this script.
if [[ "$1" == "next" ]]; then

    # `hyprshade ls` decorates its output: every line is indented, and the
    # active filter is marked with a leading "* ". Both have to come off before
    # the name is usable. Leaving the indent makes `hyprshade on "  vibrance"`
    # fail silently; leaving the asterisk is worse -- it sets a shader path that
    # does not exist, which Hyprland reports as a parser error across the top of
    # the screen. The marker also moves as the active filter changes, so
    # stripping it is what keeps the cycle order stable.
    mapfile -t filters < <(hyprshade ls | sed 's/^[[:space:]*]*//; s/[[:space:]]*$//' | grep -v '^$')
    filters+=("off")

    current_filter="blue-light-filter"
    if [ -f ~/.config/hypr/settings/hyprshade.sh ]; then
        source ~/.config/hypr/settings/hyprshade.sh
        current_filter="$hyprshade_filter"
    fi

    # Find where we are and step one along, wrapping. An unrecognised saved
    # value lands on index 0, which is a reasonable place to restart from.
    next_index=0
    for i in "${!filters[@]}"; do
        if [[ "${filters[$i]}" == "$current_filter" ]]; then
            next_index=$(( (i + 1) % ${#filters[@]} ))
            break
        fi
    done

    choice="${filters[$next_index]}"
    echo "hyprshade_filter=\"$choice\"" > ~/.config/hypr/settings/hyprshade.sh

    # Apply straight away rather than waiting for the next toggle, so cycling
    # shows you each filter as you pass through it.
    if [[ "$choice" == "off" ]]; then
        hyprshade off
        notify-send "Screen shader off"
    else
        hyprshade on "$choice"
        notify-send "Screen shader" "$choice"
    fi

else

    # Toggle Hyprshade based on the selected filter
    hyprshade_filter="blue-light-filter"

    # Check if hyprshade.sh settings file exists and load
    if [ -f ~/.config/hypr/settings/hyprshade.sh ] ;then
        source ~/.config/hypr/settings/hyprshade.sh
    fi

    # Toggle Hyprshade
    if [ "$hyprshade_filter" != "off" ] ;then
        if [ -z $(hyprshade current) ] ;then
            echo ":: hyprshade is not running"
            hyprshade on $hyprshade_filter
            notify-send "Hyprshade activated" "with $(hyprshade current)"
            echo ":: hyprshade started with $(hyprshade current)"
        else
            notify-send "Hyprshade deactivated"
            echo ":: Current hyprshade $(hyprshade current)"
            echo ":: Switching hyprshade off"
            hyprshade off
        fi
    else
        hyprshade off
        echo ":: hyprshade turned off"
    fi

fi
