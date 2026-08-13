---@module 'hl'

-- Every monitor owns a block of workspace ids. Two things depend on this:
-- The bar's workspace row filters buttons by the monitor a workspace
-- actually lives on, so a fixed block is what stops one screen's bar drawing
-- another screen's windows; and MOD+<n> keeps working as an absolute jump, now
-- with a stable meaning -- 1-3 is the ultrawide, 4-6 the right-hand 4K, 7-9 the
-- TV.
--
-- `persistent` keeps a slot alive while it is empty, which is what gives the
-- scroll wheel somewhere to land. Ids above the last block are deliberately
-- left unbound: that is where scripts/ws-scroll.sh puts a workspace made by
-- scrolling past the end of a row, and an unbound workspace is created on
-- whichever monitor has focus, so those follow the cursor instead of belonging
-- to a screen.
--
-- To add a fourth monitor, add a block. Nothing else needs touching --
-- ws-scroll.sh reads the ranges back out of Hyprland rather than repeating
-- them.
local blocks = {
    { monitor = "DP-1",     workspaces = { 1, 2, 3 } },
    { monitor = "DP-3",     workspaces = { 4, 5, 6 } },
    { monitor = "HDMI-A-1", workspaces = { 7, 8, 9 } },
}

---@type table<string, HL.WorkspaceRule[]>
local rules = {}

for _, block in ipairs(blocks) do
    rules[block.monitor] = {}

    for index, id in ipairs(block.workspaces) do
        rules[block.monitor][index] = hl.workspace_rule({
            workspace  = tostring(id),
            monitor    = block.monitor,
            persistent = true,
            -- Where the monitor lands when it has no workspace of its own yet,
            -- e.g. the first time it is switched on.
            default    = index == 1,
        })
    end
end

-- A persistent workspace whose monitor is unplugged does not politely wait for
-- it to come back: Hyprland hands it to a surviving monitor, so pulling the TV
-- cable dumps three empty workspaces onto the ultrawide's bar. Switching the
-- rules off for absent monitors lets those empties be reaped, and switching
-- them back on when the cable returns rebuilds the row.
local function match_rules_to_connected_monitors()
    local connected = {}

    for _, monitor in ipairs(hl.get_monitors()) do
        connected[monitor.name] = true
    end

    -- During startup and the monitor churn of a reload the list can come back
    -- empty, and acting on that would disable every rule at once.
    if next(connected) == nil then
        return
    end

    for name, monitor_rules in pairs(rules) do
        for _, rule in ipairs(monitor_rules) do
            rule:set_enabled(connected[name] == true)
        end
    end
end

hl.on("monitor.added", match_rules_to_connected_monitors)
hl.on("monitor.removed", match_rules_to_connected_monitors)
hl.on("config.reloaded", match_rules_to_connected_monitors)
hl.on("hyprland.start", match_rules_to_connected_monitors)
