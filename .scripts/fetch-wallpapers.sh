#!/bin/bash
# Fetch curated cyberpunk / hacker wallpaper set from wallhaven.
# Idempotent — skips files already present. Safe to re-run.

set -e

WALLDIR="$HOME/Pictures/Wallpapers"
mkdir -p "$WALLDIR"
cd "$WALLDIR"

fetch() {
    local prefix="$1"
    local query="$2"
    local min_res="${3:-1920x1080}"
    local pages="${4:-1}"
    echo "=== $query ==="
    for page in $(seq 1 "$pages"); do
        curl -s "https://wallhaven.cc/api/v1/search?q=${query}&categories=110&purity=100&atleast=${min_res}&sorting=favorites&order=desc&page=${page}" \
            | python3 -c "import sys,json; d=json.load(sys.stdin); [print(i['path']) for i in d['data'][:12]]"
    done | sort -u | while read -r url; do
        [ -z "$url" ] && continue
        fn="${prefix}-$(basename "$url")"
        [ -f "$fn" ] && continue
        curl -sL "$url" -o "$fn" && echo "  got $fn"
    done
}

# General cyberpunk / hacker set (1080p+)
fetch cyber-neuromancer         "neuromancer"
fetch cyber-blade_runner        "blade+runner"        1920x1080 2
fetch cyber-blade_runner_2049   "blade+runner+2049"   1920x1080 2
fetch cyber-blade_runner_1982   "blade+runner+1982"
fetch cyber-deckard             "deckard"
fetch cyber-rachael             "rachael+blade+runner"
fetch cyber-joi_2049            "joi+2049"
fetch cyber-ghost_in_the_shell  "ghost+in+the+shell"
fetch cyber-hackers             "hackers"
fetch cyber-cyberpunk           "cyberpunk"
fetch cyber-akira               "akira"

# GITS 4K including the Major
fetch cyber-gits4k              "ghost+in+the+shell"  3840x2160
fetch cyber-gits4k-motoko       "motoko+kusanagi"     3840x2160
fetch cyber-gits4k-major        "the+major"           3840x2160

echo
echo "Total wallpapers: $(ls "$WALLDIR" | wc -l)"
echo "Disk used: $(du -sh "$WALLDIR" | cut -f1)"
