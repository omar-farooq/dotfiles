#!/usr/bin/env bash

# List every open window, grouped by workspace, so you can check nothing is
# left unsaved on a workspace you've forgotten about before shutting down.
# DEPENDENCY: jq

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed." >&2
    exit 1
fi

# Only colourise when writing to a terminal, so piping to a file or a
# notification stays clean.
if [ -t 1 ]; then
    bold=$'\033[1m'; dim=$'\033[2m'; reset=$'\033[0m'
else
    bold=''; dim=''; reset=''
fi

monitors=$(hyprctl -j monitors)
clients=$(hyprctl -j clients)

jq -rn \
    --argjson mons "$monitors" \
    --argjson cls "$clients" \
    --arg bold "$bold" --arg dim "$dim" --arg reset "$reset" '

def pad($n): (. // "") as $s
    | $s + (if $n - ($s | length) > 0 then " " * ($n - ($s | length)) else "" end);

def plural($n): if $n == 1 then "" else "s" end;

($mons | map({ key: (.id | tostring), value: .name }) | from_entries) as $monitor_name

| if ($cls | length) == 0 then "No open windows."
  else
    ($cls
     # Widest class name, so the titles line up in one column.
     | (map(.class // "?" | length) | max) as $width
     | group_by(.workspace.id)
     # Regular workspaces in numeric order, special ones (negative ids) last.
     | sort_by([(if .[0].workspace.id < 0 then 1 else 0 end), .[0].workspace.id])
     | map(
         . as $group
         | ($group[0].workspace) as $ws
         | ($group[0].monitor | tostring) as $mon
         | [ $bold
             + (if $ws.id < 0 then $ws.name else "Workspace \($ws.id)" end)
             + $reset
             + $dim + "  ·  \($monitor_name[$mon] // "?")  ·  "
             + "\($group | length) window\(plural($group | length))" + $reset
           ]
           + ($group
              | sort_by(.class // "")
              | map("    " + ((.class // "?") | pad($width))
                    + "  " + (.title // "")
                    + (if .hidden then $dim + "  (hidden)" + $reset else "" end)
                    + (if .floating then $dim + "  (floating)" + $reset else "" end)))
           + [""]
       )
     | flatten
     | join("\n"))
    + "\n"
    + ($cls | length | "\($bold)\(.) window\(plural(.))\($reset) across ")
    + ($cls | group_by(.workspace.id) | length | "\(.) workspace\(plural(.))")
  end
'
