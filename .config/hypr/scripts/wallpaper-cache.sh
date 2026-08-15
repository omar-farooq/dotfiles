#!/bin/bash
generated_versions="$HOME/.cache/hypr/wallpaper-generated"
rm $generated_versions/*
echo ":: Wallpaper cache cleared"
notify-send "Wallpaper cache cleared"