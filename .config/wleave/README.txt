Replaces wlogout, whose upstream (ArtsyMacaw/wlogout) has gone quiet -- the
installed package was a local build from August 2024 by "Unknown Packager".
wleave is the maintained GTK4 fork: https://github.com/AMNatty/wleave

Every button delegates to ~/.config/hypr/scripts/power.sh, exactly as the
wlogout layout did, so the exit path is unchanged: power.sh "exit" uses
`killall -9 Hyprland`. NOTE that since the Hyprland config moved to Lua,
`hyprctl dispatch` parses its argument as Lua -- the old `hyprctl dispatch exit`
fails silently, and the working form is:

    sleep 1; hyprctl dispatch 'hl.dsp.exit()'

For an Arch text-based login rather than a display manager, the alternative is:

    sleep 1; loginctl terminate-user $USER

Version note: the packaged wleave is 0.7.1. Three conveniences arrived in 0.8.0
and are deliberately not used here -- "button-defaults", the "css" field, and
shell expansion inside a button's "icon" path. Icons are therefore set from
style.css with paths relative to it, which also keeps a hardcoded /home/omar
out of the repo.
