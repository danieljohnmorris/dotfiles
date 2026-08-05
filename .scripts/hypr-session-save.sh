#!/bin/bash
# Snapshot open Hyprland windows to ~/.cache/hypr-session.json
# For terminal windows we also record the working directory and, if a known
# long-running program (claude, nvim, ...) is in the process tree, its command
# line - so the restore script can bring the actual session back, not a bare shell.
mkdir -p "$HOME/.cache"

# Re-derive HYPRLAND_INSTANCE_SIGNATURE from the live socket rather than trusting
# whatever systemd cached at first Hyprland start — that value goes stale across
# Hyprland restarts and makes hyprctl fail with "Couldn't connect to ...sock".
runtime_dir="/run/user/$(id -u)/hypr"
if [ -d "$runtime_dir" ]; then
    live_sig=$(for d in "$runtime_dir"/*/; do
        sock="${d}.socket.sock"
        [ -S "$sock" ] || continue
        printf '%s\t%s\n' "$(stat -c %Y "$sock")" "$(basename "$d")"
    done | sort -n | tail -1 | cut -f2)
    [ -n "$live_sig" ] && export HYPRLAND_INSTANCE_SIGNATURE="$live_sig"
fi

# Bail out (without truncating the last good session file) if we can't talk to Hyprland.
clients_json=$(hyprctl clients -j 2>/dev/null) || exit 0
[ -n "$clients_json" ] && [ "${clients_json:0:1}" = "[" ] || exit 0

# Programs worth resuming inside a terminal. Matched against the process name.
RESUMABLE="claude|nvim|vim|htop|btop|lazygit|ssh|tmux"

# Walk the descendants of $1, print "cwd<TAB>cmdline" of the deepest resumable
# process found, else "cwd_of_deepest_shell<TAB>".
terminal_payload() {
    local root=$1 pids p name cmd cwd kids i j
    pids=("$root")
    i=0
    while [ $i -lt ${#pids[@]} ]; do
        mapfile -t kids < <(pgrep -P "${pids[$i]}" 2>/dev/null)
        [ ${#kids[@]} -gt 0 ] && pids+=("${kids[@]}")
        i=$((i + 1))
    done

    # deepest processes come last -> scan in reverse so nested programs win
    for ((j = ${#pids[@]} - 1; j >= 0; j--)); do
        p=${pids[$j]}
        name=$(ps -o comm= -p "$p" 2>/dev/null)
        [[ "$name" =~ ^($RESUMABLE)$ ]] || continue
        cmd=$(tr '\0' ' ' < "/proc/$p/cmdline" 2>/dev/null | sed 's/ *$//')
        cwd=$(readlink -f "/proc/$p/cwd" 2>/dev/null)
        printf '%s\t%s' "$cwd" "$cmd"
        return
    done

    # nothing resumable - fall back to the cwd of the deepest process
    for ((j = ${#pids[@]} - 1; j >= 0; j--)); do
        cwd=$(readlink -f "/proc/${pids[$j]}/cwd" 2>/dev/null)
        [ -n "$cwd" ] && { printf '%s\t' "$cwd"; return; }
    done
    printf '\t'
}

printf '%s' "$clients_json" | jq -c '.[] | {class, title, workspace: .workspace.name, pid, at, size}' |
    while read -r entry; do
        pid=$(jq -r '.pid' <<<"$entry")
        IFS=$'\t' read -r cwd cmd <<<"$(terminal_payload "$pid")"
        jq -c --arg cwd "$cwd" --arg cmd "$cmd" '. + {cwd: $cwd, cmd: $cmd}' <<<"$entry"
    done | jq -s '.' > "$HOME/.cache/hypr-session.json"
