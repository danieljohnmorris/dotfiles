#!/bin/bash
# Cava audio visualizer for Waybar custom module
# Outputs JSON with Unicode block characters

cava -p ~/.config/cava/config | awk -F';' '
BEGIN {
    split(" ▁▂▃▄▅▆▇", blocks, "")
    silent_count = 0
}
{
    out = ""
    is_silent = 1
    for (i = 1; i <= NF; i++) {
        val = int($i)
        if (val < 0) val = 0
        if (val > 7) val = 7
        if (val > 0) is_silent = 0
        out = out blocks[val + 1]
    }
    if (is_silent) {
        silent_count++
        if (silent_count > 60) {
            printf "{\"text\": \"\", \"class\": \"silent\"}\n"
            fflush()
            next
        }
    } else {
        silent_count = 0
    }
    gsub(/"/, "\\\"", out)
    printf "{\"text\": \"%s\", \"class\": \"playing\"}\n", out
    fflush()
}'
