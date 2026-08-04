#!/bin/bash
# Render fastfetch with a 2x2 grid layout + tachikoma image on the left

SECTIONS=~/.config/fastfetch/sections
OUT=$(mktemp -d)
trap 'rm -rf "$OUT"' EXIT

for s in hw sw age rice; do
    fastfetch --config "$SECTIONS/$s.jsonc" > "$OUT/$s.txt"
done

python3 - "$OUT" <<'PYEOF' > "$OUT/wrapper.jsonc"
import re, sys, os, json
d = sys.argv[1]
ansi = re.compile(r'\x1b\[[0-9;]*[A-Za-z]')
def vlen(s): return len(ansi.sub('', s))
def pad(lines, w): return [l + ' ' * max(0, w - vlen(l)) for l in lines]
def read(f):
    with open(os.path.join(d, f)) as fh:
        return fh.read().rstrip('\n').split('\n')
def truncate(lines, w):
    out = []
    for l in lines:
        if vlen(l) <= w:
            out.append(l); continue
        # Truncate preserving ANSI codes; drop chars until visible width fits
        result, visible = '', 0
        i = 0
        while i < len(l) and visible < w - 1:
            m = ansi.match(l, i)
            if m:
                result += m.group(); i = m.end()
            else:
                result += l[i]; visible += 1; i += 1
        result += '…\x1b[0m'
        out.append(result)
    return out

def merge(L, R, w=38):
    L = pad(truncate(read(L), w), w)
    R = truncate(read(R), w)
    n = max(len(L), len(R))
    L += [' ' * w] * (n - len(L))
    R += [''] * (n - len(R))
    return [f"{a}  {b}" for a, b in zip(L, R)]

lines = merge('hw.txt', 'sw.txt') + [''] + merge('age.txt', 'rice.txt')
mods = ["break"] + [{"type": "custom", "format": ln} for ln in lines]
cfg = {
    "logo": {
        "type": "kitty-direct",
        "source": "~/.config/nvim/assets/tachikoma.png",
        "width": 40,
        "padding": {"top": 2, "right": 4, "left": 2}
    },
    "modules": mods
}
print(json.dumps(cfg, indent=2))
PYEOF

fastfetch --config "$OUT/wrapper.jsonc"
