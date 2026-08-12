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

# Since Hyprland 0.56 the config is Lua, and `hyprctl dispatch` parses its
# argument as Lua rather than the old `dispatch <name> <args>` syntax. Note that
# a dpms dispatch with unrecognised args silently degrades to "toggle every
# monitor", so these wrappers must build the table exactly.
dpms() { # $1 = on|off, $2 = monitor name
    hyprctl dispatch "hl.dsp.dpms({ action = \"$1\", monitor = \"$2\" })" > /dev/null
}

move_workspace_to() { # $1 = monitor name
    hyprctl dispatch "hl.dsp.workspace.move({ monitor = \"$1\" })" > /dev/null
}

# Get the name of the currently focused monitor
FOCUSED_MONITOR=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true).name')

if [ "$FOCUSED_MONITOR" = "$TV_MONITOR" ]; then
    # STATE: TV is focused. ACTION: Switch to Desktop.
    hyprctl notify -1 3000 "rgb(aaffaa)" "Switching to Desktop Mode"

    # Find which desktop monitor to switch to, prioritizing the primary one.
    # `hyprctl monitors all` detects monitors that might be off (DPMS).
    if hyprctl monitors all | grep -q "$PRIMARY_DESK_MONITOR"; then
        dpms on "$PRIMARY_DESK_MONITOR"
        move_workspace_to "$PRIMARY_DESK_MONITOR"
        # Also turn on the secondary monitor if it exists
        if hyprctl monitors all | grep -q "$SECONDARY_DESK_MONITOR"; then
            dpms on "$SECONDARY_DESK_MONITOR"
        fi
    elif hyprctl monitors all | grep -q "$SECONDARY_DESK_MONITOR"; then
        # Fallback to the secondary monitor
        dpms on "$SECONDARY_DESK_MONITOR"
        move_workspace_to "$SECONDARY_DESK_MONITOR"
    else
        hyprctl notify -1 5000 "rgb(ff1111)" "Error: No desktop monitors detected."
        exit 1
    fi
    
    notify-send "TV off" "Moving back to desktop mode"
    # Finally, turn the TV off
    #dpms off "$TV_MONITOR"

else
    # STATE: A Desktop monitor is focused. ACTION: Switch to TV.
    hyprctl notify -1 3000 "rgb(aaffaa)" "Switching to TV Mode"

    # First, ensure the TV is actually connected before we try to use it.
    if ! hyprctl monitors all | grep -q "$TV_MONITOR"; then
        hyprctl notify -1 5000 "rgb(ff1111)" "Error: TV ($TV_MONITOR) is not connected."
        exit 1
    fi

    dpms on "$TV_MONITOR"
    move_workspace_to "$TV_MONITOR"

    # Turn off both desktop monitors
    dpms off "$PRIMARY_DESK_MONITOR"
    dpms off "$SECONDARY_DESK_MONITOR"
    notify-send "TV on" "Turned off other monitors"
fi

