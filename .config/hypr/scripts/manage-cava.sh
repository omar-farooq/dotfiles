#!/usr/bin/env bash

# --- Configuration ---
# The monitor where Cava should appear. Find with `hyprctl monitors`.
TARGET_MONITOR="DP-1"

# A unique WM_CLASS for this specific Alacritty window.
# We make it unique so it doesn't conflict with other rules.
WM_CLASS="alacritty-cava-bg"
HOME_DIR="/home/omar"

# The command to launch Cava.
CAVA_COMMAND="alacritty --class $WM_CLASS --config-file $HOME_DIR/.config/alacritty/cava.toml -e $HOME_DIR/.config/hypr/scripts/cava.sh"

# --- Script Logic ---

# We need to store the Process ID (PID) of the Cava Alacritty window to kill it later.
cava_pid=""

function launch_cava() {
    # Only launch if it's not already running
    if [ -z "$cava_pid" ]; then
        echo "Monitor '$TARGET_MONITOR' detected. Launching Cava."
        # Launch the command in the background
        $CAVA_COMMAND &
        # Store its PID
        cava_pid=$!
    fi
}

function kill_cava() {
    # Only kill if we have a PID
    if [ -n "$cava_pid" ]; then
        echo "Monitor '$TARGET_MONITOR' removed. Killing Cava (PID: $cava_pid)."
        # Kill the process and any children
        kill -9 "$cava_pid" >/dev/null 2>&1
        # Clear the PID
        cava_pid=""
    fi
}

# Initial check: if the monitor is already active on script startup, launch Cava.
if hyprctl monitors | grep -q "Monitor $TARGET_MONITOR"; then
    launch_cava
fi

# Listen for events using socat. The while loop will run forever.
socat - "UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r event; do
    # Event for monitor being connected or turned on
    if [[ $event == "monitoradded>>$TARGET_MONITOR" ]]; then
        launch_cava
    # Event for monitor being disconnected or turned off
    elif [[ $event == "monitorremoved>>$TARGET_MONITOR" ]]; then
        kill_cava
    fi
done

