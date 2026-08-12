#!/usr/bin/env bash
#
# Catch hyprctl calls that stopped working when the Hyprland config moved to Lua.
#
# All of these fail *silently* -- they print "ok" or exit 0 while doing nothing,
# or in the case of dpms quietly fall back to toggling every monitor. That makes
# them nearly impossible to spot by using the desktop, so they get caught here.
#
# Usage:  lint-hyprctl.sh [file ...]     (no args = every tracked file)

set -uo pipefail

self=$(basename "${BASH_SOURCE[0]}")
status=0

if [ "$#" -gt 0 ]; then
    files=("$@")
else
    mapfile -t files < <(git ls-files)
fi

report() { # $1 = file, $2 = line no, $3 = line, $4 = why
    printf '%s:%s: %s\n    %s\n' "$1" "$2" "$4" "$(echo "$3" | sed 's/^[[:space:]]*//')" >&2
    status=1
}

for f in "${files[@]}"; do
    [ -f "$f" ] || continue
    case "$f" in
        *"$self") continue ;;      # this file necessarily contains the patterns
        *.png|*.jpg|*.AppImage|*.zip) continue ;;
    esac
    grep -Iq . "$f" 2>/dev/null || continue   # skip binaries

    n=0
    while IFS= read -r line; do
        n=$((n + 1))
        trimmed=${line#"${line%%[![:space:]]*}"}
        # Prose in comments explaining this very migration is not a finding.
        case "$trimmed" in \#*|--*|//*) continue ;; esac
        # Nor is prose that quotes the old syntax in backticks, which is how
        # the notes and READMEs in this repo refer to it. Match on the stripped
        # text but keep the original line for the report.
        scan=$(printf '%s' "$line" | sed 's/`[^`]*`//g')
        [ -n "${scan//[[:space:]]/}" ] || continue

        if [[ $scan =~ hyprctl[[:space:]]+keyword ]]; then
            report "$f" "$n" "$line" \
                "\`hyprctl keyword\` does not work with a Lua config; use: hyprctl eval 'hl.config({ ... })'"
        fi

        # `hyprctl dispatch` now parses its argument as Lua, so the next token
        # has to be an hl.* expression rather than a bare dispatcher name.
        if [[ $scan =~ hyprctl[[:space:]]+dispatch[[:space:]]+ ]] \
           && ! [[ $scan =~ hyprctl[[:space:]]+dispatch[[:space:]]+[\'\"\\]*hl\. ]]; then
            report "$f" "$n" "$line" \
                "legacy \`hyprctl dispatch <name> <args>\`; use an hl.dsp.* Lua expression"
        fi

        if [[ $scan =~ workspaceopt ]]; then
            report "$f" "$n" "$line" \
                "\`workspaceopt\` is deprecated and has no Lua dispatcher; iterate windows instead"
        fi
    done < "$f"
done

if [ "$status" -ne 0 ]; then
    echo >&2
    echo "hyprctl lint failed. See .githooks/lint-hyprctl.sh for the rationale." >&2
fi
exit "$status"
