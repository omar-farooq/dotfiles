# Preload Wallpapers
preload = WALLPAPER

# Set Wallpapers
#
# Block form, not the old comma-prefixed one-liner: hyprpaper 0.8 no longer
# accepts that and parses it into no wallpaper at all -- a black screen, with
# hyprpaper still running and nothing obvious in the way of an error. The
# checked-in hyprpaper.conf had already been hand-fixed to this form, but the
# template it gets regenerated from had not, so every wallpaper or effect
# change quietly put the broken syntax back.
#
# Careful editing this: wallpaper.sh substitutes every occurrence of the
# placeholder token, comments included, so the token must not appear in prose.
wallpaper {
    monitor =
    path = WALLPAPER
}

# Disable Splash
splash = false
