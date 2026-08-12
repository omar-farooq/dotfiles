#!/bin/bash
cache_file="$HOME/.cache/toggle_animation"

# `hyprctl keyword` refuses to run against a Lua config ("keyword can't work
# with non-legacy parsers. Use eval."), so set the option through hl.config.
set_animations() { # $1 = true|false
    hyprctl eval "hl.config({ animations = { enabled = $1 } })" > /dev/null
}

# The active config is animation.lua now; animation.conf is only still around
# for the legacy variation switcher, so check whichever one is present.
animation_config="$HOME/.config/hypr/conf/animation.lua"
[ -f "$animation_config" ] || animation_config="$HOME/.config/hypr/conf/animation.conf"

if [[ $(cat "$animation_config") == *"disabled"* ]]; then
    echo ":: Toggle blocked by disabled variation."
else
    if [ -f $cache_file ] ;then
        set_animations true
        rm $cache_file
    else
        set_animations false
        touch $cache_file
    fi
fi