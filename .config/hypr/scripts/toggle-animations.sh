#!/bin/bash
cache_file="$HOME/.cache/toggle_animation"

# `hyprctl keyword` refuses to run against a Lua config ("keyword can't work
# with non-legacy parsers. Use eval."), so set the option through hl.config.
set_animations() { # $1 = true|false
    hyprctl eval "hl.config({ animations = { enabled = $1 } })" > /dev/null
}

animation_config="$HOME/.config/hypr/conf/animation.lua"

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