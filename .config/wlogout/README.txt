Select Logout Command depending on your setup:

Use for Display Manager e.g., sddm (DEFAULT)
sleep 1; hyprctl dispatch 'hl.dsp.exit()'

Use for Arch Linux text based login
sleep 1; loginctl terminate-user $USER

NOTE: since the Hyprland config moved to Lua, `hyprctl dispatch` parses its
argument as Lua. The old `hyprctl dispatch exit` no longer works and fails
silently, hence the hl.dsp.exit() form above.

This layout does not use either command directly: every button delegates to
~/.config/hypr/scripts/power.sh, whose "exit" branch uses `killall -9 Hyprland`.
