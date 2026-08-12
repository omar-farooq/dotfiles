#!/bin/bash
#     _    _ _  __ _             _    
#    / \  | | |/ _| | ___   __ _| |_  
#   / _ \ | | | |_| |/ _ \ / _` | __| 
#  / ___ \| | |  _| | (_) | (_| | |_  
# /_/   \_\_|_|_| |_|\___/ \__,_|\__| 
#                                     

# The `workspaceopt allfloat` dispatcher is deprecated and has no Lua
# equivalent, so do it by hand: if anything on the workspace is still tiled,
# float everything, otherwise tile everything back.
hyprctl eval '
local ws = hl.get_active_workspace()
if ws then
    local windows = hl.get_workspace_windows(ws)
    local any_tiled = false
    for _, w in ipairs(windows) do
        if not w.floating then any_tiled = true; break end
    end
    local action = any_tiled and "on" or "off"
    for _, w in ipairs(windows) do
        hl.dispatch(hl.dsp.window.float({ action = action, window = w }))
    end
end
'
notify-send "Windows on this workspace toggled to floating/tiling"
