"""pinmap.py -- the full MCU pin table, derived from the extracted schematic
vectors only (no images, no OCR guessing).

For every MCU pin this reports:
  * the net it belongs to (as a bounding box),
  * the "net labels" sitting ON its wire, and
  * the far ends of the net, with the designators/pin numbers printed next to
    them -- i.e. what the pin actually drives.

Placement conventions measured on this sheet (and used as rulers):
    pin number            -> anchor y is 5.1 px ABOVE the pin line
    pin name / net label   -> anchor y is 5.1 px ABOVE the wire it belongs to
    (pin name inside a symbol -> anchor y is 7.3 px BELOW the line)

Usage: python pinmap.py [--dir refs/_vector]
"""
import argparse
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from schem_net import load, Netlist, point_seg_dist, bbox  # noqa: E402

# MCU symbol geometry (verified: right edge x=2050.55, pins to x=2124.75;
# left edge x=1730.1, pins out to x=1655.9)
RIGHT_X0, RIGHT_X1 = 2050.55, 2124.75
LEFT_X0, LEFT_X1 = 1655.9, 1730.1

# DIP40 pin numbers -> port name, in the order the schematic lists them
RIGHT_PORTS = {
    0: 'P0.0', 1: 'P0.1', 2: 'P0.2', 3: 'P0.3', 4: 'P0.4', 5: 'P0.5',
    6: 'P0.6', 7: 'P0.7',
    8: 'P1.0', 9: 'P1.1', 10: 'P1.2', 11: 'P1.3', 12: 'P1.4', 13: 'P1.5',
    14: 'P1.6', 15: 'P1.7',
    16: 'P2.0', 17: 'P2.1', 18: 'P2.2', 19: 'P2.3', 20: 'P2.4', 21: 'P2.5',
    22: 'P2.6', 23: 'P2.7',
}
DIP = {0: 39, 1: 38, 2: 37, 3: 36, 4: 35, 5: 34, 6: 33, 7: 32,
       8: 1, 9: 2, 10: 3, 11: 4, 12: 5, 13: 6, 14: 7, 15: 8,
       16: 21, 17: 22, 18: 23, 19: 24, 20: 25, 21: 26, 22: 27, 23: 28}

LEFT_PORTS = {  # DIP40 pin number -> function
    29: 'PSEN', 30: 'ALE', 10: 'P3.0/RXD', 11: 'P3.1/TXD',
    12: 'P3.2/INT0', 13: 'P3.3/INT1', 14: 'P3.4/T0', 15: 'P3.5/T1',
    16: 'P3.6/WR', 17: 'P3.7/RD', 19: 'XTAL1', 18: 'XTAL2',
    9: 'RST', 20: 'GND', 40: 'VCC', 31: 'EA',
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dir', default='refs/_vector')
    args = ap.parse_args()

    segs, dots, labels = load(args.dir)
    nl = Netlist(segs, dots)
    nl.build()
    nets = nl.nets()

    def labels_on_wire(root, side):
        """Net labels: text whose anchor sits 5.1 px above a wire of this net."""
        out = []
        for i in nets[root]['segs']:
            s = segs[i]
            if abs(s[1] - s[3]) > 0.5:
                continue
            y = s[1]
            lo, hi = min(s[0], s[2]), max(s[0], s[2])
            for (lx, ly, em, t) in labels:
                if abs(ly + 5.1 - y) <= 1.6 and lo - 6 <= lx <= hi + 6:
                    out.append(t)
        return out

    def pin_number(root, side):
        """The pin number printed above the pin's own line."""
        for i in nets[root]['segs']:
            s = segs[i]
            if abs(s[1] - s[3]) > 0.5:
                continue
            y = s[1]
            lo, hi = min(s[0], s[2]), max(s[0], s[2])
            for (lx, ly, em, t) in labels:
                if abs(ly + 5.1 - y) <= 1.6 and lo - 4 <= lx <= hi + 4:
                    return t
        return ''

    # ---------- right-hand pins ----------
    print('=' * 78)
    print('MCU 右侧引脚 (P0/P1/P2)')
    print('=' * 78)
    pins = []
    for i, s in enumerate(segs):
        if (abs(s[1] - s[3]) < 0.5
                and abs(min(s[0], s[2]) - RIGHT_X0) < 1.5
                and abs(max(s[0], s[2]) - RIGHT_X1) < 1.5):
            pins.append((s[1], i))
    pins.sort()
    for (y, i) in pins:
        root = nl.find(('e', i, 0))
        bb = bbox(segs, nets[root]['segs'])
        num = pin_number(root, 'R')
        names = labels_on_wire(root, 'R')
        far = [e for e in sorted(nl.free_ends(root, nets)) if e[0] > RIGHT_X1 + 3]
        desc = []
        for (ex, ey) in far:
            near = [t for t in nl.labels_near(ex, ey, labels, 28)
                    if not t.replace('.', '').isdigit() or len(t) > 2]
            desc.append(f'({ex:.0f},{ey:.0f})' + (f'[{",".join(sorted(set(near)))}]' if near else ''))
        print(f'  y={y:7.1f}  引脚号={num:<3} 导线网标号={sorted(set(names)) or "-"}')
        print(f'          net bbox=({bb[0]:.0f},{bb[1]:.0f})-({bb[2]:.0f},{bb[3]:.0f})  segs={len(nets[root]["segs"])}')
        print(f'          远端: {" ".join(desc) if desc else "（只连到上拉排阻/无其它外设）"}')

    # ---------- left-hand pins ----------
    print()
    print('=' * 78)
    print('MCU 左侧引脚 (P3 / 控制)')
    print('=' * 78)
    lpins = []
    for i, s in enumerate(segs):
        if (abs(s[1] - s[3]) < 0.5
                and abs(min(s[0], s[2]) - LEFT_X0) < 1.5
                and abs(max(s[0], s[2]) - LEFT_X1) < 1.5):
            lpins.append((s[1], i))
    lpins.sort()
    for (y, i) in lpins:
        root = nl.find(('e', i, 0))
        bb = bbox(segs, nets[root]['segs'])
        num = pin_number(root, 'L')
        names = labels_on_wire(root, 'L')
        far = [e for e in sorted(nl.free_ends(root, nets)) if e[0] < LEFT_X0 - 3]
        desc = []
        for (ex, ey) in far:
            near = [t for t in nl.labels_near(ex, ey, labels, 28)]
            desc.append(f'({ex:.0f},{ey:.0f})' + (f'[{",".join(sorted(set(near)))}]' if near else ''))
        print(f'  y={y:7.1f}  引脚号={num:<3} 导线网标号={sorted(set(names)) or "-"}')
        print(f'          net bbox=({bb[0]:.0f},{bb[1]:.0f})-({bb[2]:.0f},{bb[3]:.0f})  segs={len(nets[root]["segs"])}')
        print(f'          远端: {" ".join(desc) if desc else "（未连接）"}')


if __name__ == '__main__':
    main()
