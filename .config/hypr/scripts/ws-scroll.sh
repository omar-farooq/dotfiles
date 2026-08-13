#!/usr/bin/env bash
#  __        __         _
#  \ \      / /__  _ __| | _____ _ __   __ _  ___ ___
#   \ \ /\ / / _ \| '__| |/ / __| '_ \ / _` |/ __/ _ \
#    \ V  V / (_) | |  |   <\__ \ |_) | (_| | (_|  __/
#     \_/\_/ \___/|_|  |_|\_\___/ .__/ \__,_|\___\___|
#                               |_|
#
# Move between the workspaces of one monitor, for the bar's scroll wheel.
#
#   ws-scroll.sh next   forward; past the last workspace it makes a new one
#   ws-scroll.sh prev   backward; stops at the first, it does not wrap round
#
# Only "next" creates, so a workspace is never made on the way back. Hyprland's
# focused monitor follows the cursor -- hovering a bar is enough -- so this
# always acts on the screen whose bar is being scrolled.
# DEPENDENCY: jq

set -euo pipefail

direction="${1:-next}"

contains() { # $1 = needle, rest = haystack
    local needle=$1
    shift
    [[ " $* " == *" $needle "* ]]
}

# `monitors` carries both the focused monitor and its active workspace, so this
# is one round trip rather than two.
read -r monitor current < <(
    hyprctl -j monitors | jq -r '.[] | select(.focused) | "\(.name) \(.activeWorkspace.id)"'
)

workspaces_json=$(hyprctl -j workspaces)

# This monitor's own workspaces, in order. Special workspaces have negative ids
# and are not part of the row.
mapfile -t ids < <(
    jq -r --arg m "$monitor" '[.[] | select(.monitor == $m and .id > 0) | .id] | sort | .[]' \
        <<< "$workspaces_json"
)

target=""

case "$direction" in
next)
    for id in "${ids[@]}"; do
        if ((id > current)); then
            target=$id
            break
        fi
    done

    # End of the row, so mint a new workspace. Focusing an id that does not
    # exist yet creates it on the focused monitor.
    if [[ -z $target ]]; then
        mapfile -t used < <(jq -r '.[].id' <<< "$workspaces_json")

        # Ids that conf/workspaces/default.lua pins to a monitor are off
        # limits: taking one would claim a slot belonging to another screen and
        # drag that workspace over here. Reading the rules back from Hyprland
        # rather than hardcoding the range means adding a monitor -- or
        # resizing a block -- needs no change in this script. Note the pinned
        # ids stay reserved even while their monitor is unplugged, which is
        # what keeps the numbering stable across a TV being switched off.
        mapfile -t reserved < <(
            hyprctl -j workspacerules | jq -r '.[].workspaceString | select(test("^[0-9]+$"))'
        )

        # Counting up from the current id rather than from 1 keeps "next"
        # going forwards on a monitor with no block of its own: the id it just
        # left is free again the moment it empties, so starting from 1 would
        # hand back the same pair of ids over and over.
        target=$((current + 1))
        while contains "$target" ${used[*]:-} ${reserved[*]:-}; do
            ((target++))
        done
    fi
    ;;
prev)
    for id in "${ids[@]}"; do
        if ((id < current)); then
            target=$id
        fi
    done

    # Already at the front of the row. Going nowhere is the point: wrapping
    # round to the far end made scrolling down off slot 1 land on slot 3.
    [[ -z $target ]] && exit 0
    ;;
*)
    echo "usage: ${0##*/} next|prev" >&2
    exit 1
    ;;
esac

# Since Hyprland 0.56 the config is Lua and `hyprctl dispatch` parses its
# argument as Lua rather than the old `dispatch <name> <args>` syntax.
hyprctl dispatch "hl.dsp.focus({ workspace = $target })" > /dev/null
