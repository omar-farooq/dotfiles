-- Converted from hyprland.conf by hyprconf2lua v1.4.0, then reviewed by hand.
-- https://github.com/Prateek-squadron/hyprconf2lua

---@module 'hl'

--  _   _                  _                 _
-- | | | |_   _ _ __  _ __| | __ _ _ __   __| |
-- | |_| | | | | '_ \| '__| |/ _` | '_ \ / _` |
-- |  _  | |_| | |_) | |  | | (_| | | | | (_| |
-- |_| |_|\__, | .__/|_|  |_|\__,_|_| |_|\__,_|
--        |___/|_|
--
-- -----------------------------------------------------
-- IMPORTANT: Don't overwrite ML4W configuration.
-- Create your own custom configuration variation instead.
-- https://github.com/mylinuxforwork/dotfiles/wiki/Configuration-Variations
-- -----------------------------------------------------

-- hyprlang's `source =` becomes require(). Module names are relative to
-- ~/.config/hypr (package.path is set to `<config dir>/?.lua`), and each module
-- applies its settings as a side effect rather than returning a table.

-- -----------------------------------------------------
-- Monitor
-- -----------------------------------------------------
require("conf.monitor")

-- -----------------------------------------------------
-- Autostart
-- -----------------------------------------------------
require("conf.autostart")

-- -----------------------------------------------------
-- Cursor
-- -----------------------------------------------------
require("conf.cursor")

-- -----------------------------------------------------
-- Environment
-- -----------------------------------------------------
require("conf.environment")

-- -----------------------------------------------------
-- Keyboard
-- -----------------------------------------------------
require("conf.keyboard")

-- -----------------------------------------------------
-- Load pywal color file
-- -----------------------------------------------------
-- Was `source = ~/.cache/wal/colors-hyprland.conf`, which defined $color0..$color15
-- as hyprlang variables. Lua has no equivalent, so conf/colors.lua parses that
-- same pywal file into a table and the modules that need a colour require() it
-- directly -- see conf/windows/*.lua. Nothing to pull in here.

-- -----------------------------------------------------
-- Load configuration files
-- -----------------------------------------------------
require("conf.window")
require("conf.workspace")
require("conf.decoration")
require("conf.layout")
require("conf.misc")
require("conf.keybinding")
require("conf.windowrule")

-- -----------------------------------------------------
-- Animation
-- -----------------------------------------------------
require("conf.animation")

-- -----------------------------------------------------
-- Custom
-- -----------------------------------------------------
require("conf.custom")

-- conf/ml4w.lua was dissolved rather than renamed: its environment variables
-- are in conf/environments/base.lua and its window rules in
-- conf/windowrules/default.lua, both of which are already required above.

-- -----------------------------------------------------
-- Environment for xdg-desktop-portal-hyprland
-- -----------------------------------------------------
hl.on("hyprland.start", function()
    hl.exec_cmd(
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP && systemctl --user reset-failed xdg-desktop-portal xdg-desktop-portal-hyprland && systemctl --user start xdg-desktop-portal-hyprland xdg-desktop-portal")
end)
