#!/bin/bash
#  _              _     _           _ _
# | | _____ _   _| |__ (_)_ __   __| (_)_ __   __ _ ___
# | |/ / _ \ | | | '_ \| | '_ \ / _` | | '_ \ / _` / __|
# |   <  __/ |_| | |_) | | | | | (_| | | | | | (_| \__ \
# |_|\_\___|\__, |_.__/|_|_| |_|\__,_|_|_| |_|\__, |___/
#           |___/                             |___/
#
# Show every registered keybinding in rofi.
#
# This reads the binds straight out of the running compositor rather than
# parsing a config file, so it can never drift from what is actually bound.
# The labels come from the `description` field on each hl.bind() call.
# DEPENDENCY: jq

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed." >&2
    exit 1
fi

keybinds=$(hyprctl -j binds | jq -r '
    # Hyprland packs the modifiers into a bitmask; there are no bitwise
    # operators in jq, so divide and test the low bit.
    def bit($mask; $b): (($mask / $b) | floor) % 2 == 1;

    def mods($mask):
        [ (if bit($mask; 64) then "SUPER" else empty end),
          (if bit($mask;  4) then "CTRL"  else empty end),
          (if bit($mask;  8) then "ALT"   else empty end),
          (if bit($mask;  1) then "SHIFT" else empty end) ];

    .[]
    # Skip anything left undescribed rather than showing a blank row.
    | select(.has_description)
    | ((mods(.modmask) + [.key]) | join(" + ")) as $keys
    | (if .submap != "" then "  (submap: " + .submap + ")" else "" end) as $submap
    # rofi runs with -markup, so anything user-supplied has to be escaped.
    | "<b>" + ($keys | @html) + "</b>" + ($submap | @html)
      + "\r" + (.description | @html)
')

if [ -z "$keybinds" ]; then
    echo "Error: no keybindings returned by hyprctl." >&2
    exit 1
fi

sleep 0.2
rofi -dmenu -i -markup -eh 2 -replace -p "Keybinds" -config ~/.config/rofi/config-compact.rasi <<< "$keybinds"
