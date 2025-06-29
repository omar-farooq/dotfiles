#!/usr/bin/env bash

# A script to toggle the current workspace between desktop monitors and a TV.
# It determines the current state by checking which monitor has focus.
# DEPENDENCY: jq (sudo pacman -S jq / sudo apt install jq)

# --- Configuration ---
TV_MONITOR="HDMI-A-1"
PRIMARY_DESK_MONITOR="DP-3"
SECONDARY_DESK_MONITOR="DP-1"
# --- End Configuration ---

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    hyprctl notify -1 5000 "rgb(ff1111)" "Error: jq is not installed. Please install it to run this script."
    exit 1
fi

# Get the name of the currently focused monitor
FOCUSED_MONITOR=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true).name')

if [ "$FOCUSED_MONITOR" = "$TV_MONITOR" ]; then
    # STATE: TV is focused. ACTION: Switch to Desktop.
    hyprctl notify -1 3000 "rgb(aaffaa)" "Switching to Desktop Mode"

    # Find which desktop monitor to switch to, prioritizing the primary one.
    # `hyprctl monitors all` detects monitors that might be off (DPMS).
    if hyprctl monitors all | grep -q "$PRIMARY_DESK_MONITOR"; then
        hyprctl dispatch dpms on "$PRIMARY_DESK_MONITOR"
        hyprctl dispatch movecurrentworkspacetomonitor "$PRIMARY_DESK_MONITOR"
        # Also turn on the secondary monitor if it exists
        if hyprctl monitors all | grep -q "$SECONDARY_DESK_MONITOR"; then
            hyprctl dispatch dpms on "$SECONDARY_DESK_MONITOR"
        fi
    elif hyprctl monitors all | grep -q "$SECONDARY_DESK_MONITOR"; then
        # Fallback to the secondary monitor
        hyprctl dispatch dpms on "$SECONDARY_DESK_MONITOR"
        hyprctl dispatch movecurrentworkspacetomonitor "$SECONDARY_DESK_MONITOR"
    else
        hyprctl notify -1 5000 "rgb(ff1111)" "Error: No desktop monitors detected."
        exit 1
    fi
    
    notify-send "TV off" "Moving back to desktop mode"
    # Finally, turn the TV off
    #hyprctl dispatch dpms off "$TV_MONITOR"

else
    # STATE: A Desktop monitor is focused. ACTION: Switch to TV.
    hyprctl notify -1 3000 "rgb(aaffaa)" "Switching to TV Mode"

    # First, ensure the TV is actually connected before we try to use it.
    if ! hyprctl monitors all | grep -q "$TV_MONITOR"; then
        hyprctl notify -1 5000 "rgb(ff1111)" "Error: TV ($TV_MONITOR) is not connected."
        exit 1
    fi

    hyprctl dispatch dpms on "$TV_MONITOR"
    hyprctl dispatch movecurrentworkspacetomonitor "$TV_MONITOR"
    
    # Turn off both desktop monitors
    hyprctl dispatch dpms off "$PRIMARY_DESK_MONITOR"
    hyprctl dispatch dpms off "$SECONDARY_DESK_MONITOR"
    notify-send "TV on" "Turned off other monitors"
fi

