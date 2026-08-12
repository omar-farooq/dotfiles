-- Replaces `source = ~/.cache/wal/colors-hyprland.conf`.
--
-- pywal writes that file in hyprlang syntax (`$color11 = rgb(5A6592)`), which the
-- Lua config can't `source`. It's still regenerated on every wallpaper change, so
-- rather than freezing the palette we parse it here and hand back a table.
--
-- Usage:
--   local colors = require("conf.colors")
--   colors.color11 --> "rgb(5A6592)"

---@module 'hl'

local colors = {
    background = "rgb(000000)",
    foreground = "rgb(ffffff)",
}

-- Fallbacks, so a missing/not-yet-generated pywal file can't leave a nil colour
-- in a `col.active_border` and fail the whole config parse.
for i = 0, 15 do
    colors["color" .. i] = "rgb(ffffff)"
end

local path = (os.getenv("HOME") or "~") .. "/.cache/wal/colors-hyprland.conf"
local file = io.open(path, "r")

if file then
    for line in file:lines() do
        local key, value = line:match("^%s*%$([%w_]+)%s*=%s*(.-)%s*$")
        if key and value ~= "" then
            colors[key] = value
        end
    end
    file:close()
end

return colors
