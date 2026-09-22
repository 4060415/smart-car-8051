"""Independent re-check of the SM1 (7-seg) segment mapping.

Method (no images involved -- pure numbers from refs/_vector):
  * each MCU P2.x pin has a known pin-line y (validated against the DIP40 pin
    numbers printed on the schematic);
  * follow that pin's net to the wire end that reaches the display (x ~= 2470);
  * SM1's own pin labels are text items: pin NUMBER at x~=2439 and pin NAME at
    x~=2487.  Two placement conventions were measured on the MCU and are used
    here as an independent ruler:
        pin number sits 5.1 px ABOVE its pin line
        pin name   sits 7.3 px BELOW its pin line (baseline anchor)
  * a wire matches a SM1 pin when its y equals that pin's line y.
"""
import sys
sys.path.insert(0, 'tools')
from schem_net import load, Netlist, bbox

segs, dots, labels = load('refs/_vector')
nl = Netlist(segs, dots)
nl.build()
nets = nl.nets()

# ---- SM1 pin labels -------------------------------------------------------
num_labels, name_labels = [], []
for (lx, ly, em, t) in labels:
    if abs(lx - 2439.4) < 3 or abs(lx - 2428.5) < 3:
        num_labels.append((ly, t))
    if abs(lx - 2487.3) < 3:
        name_labels.append((ly, t))
num_labels.sort()
name_labels.sort()

print('SM1 pin-number labels (anchor y) and pin-name labels (anchor y):')
for (y, t) in num_labels:
    print(f'    number "{t:<3}" anchor y={y:8.2f}  -> pin line y={y + 5.1:8.2f}')
for (y, t) in name_labels:
    print(f'    name   "{t:<3}" anchor y={y:8.2f}  -> pin line y={y - 7.3:8.2f}')

pin_by_line = {}
for (y, t) in num_labels:
    pin_by_line[round(y + 5.1, 1)] = ('number', t)
for (y, t) in name_labels:
    pin_by_line.setdefault(round(y - 7.3, 1), ('name', t))

# ---- trace each P2 pin ----------------------------------------------------
print('\nTracing P2.0..P2.7 to the display:')
p2 = {0: 1230.3, 1: 1255.2, 2: 1279.7, 3: 1304.2, 4: 1329.0, 5: 1353.6,
      6: 1378.4, 7: 1402.9}
pin_dip = {0: 21, 1: 22, 2: 23, 3: 24, 4: 25, 5: 26, 6: 27, 7: 28}

for bit in range(8):
    y = p2[bit]
    idx = None
    for i, s in enumerate(segs):
        if (abs(s[1] - s[3]) < 0.5 and abs(s[1] - y) < 0.6
                and abs(min(s[0], s[2]) - 2050.55) < 1.5
                and abs(max(s[0], s[2]) - 2124.75) < 1.5):
            idx = i
            break
    if idx is None:
        print(f'  P2.{bit}: pin stub not found')
        continue
    root = nl.find(('e', idx, 0))
    ends = nl.free_ends(root, nets)
    far = sorted([e for e in ends if e[0] > 2400], key=lambda e: -e[1])
    lab = [t for (t, _, _) in nl.labels_on(root, nets, labels)]
    if far:
        ex, ey = far[0]
        match = ''
        for (ly, t) in num_labels:
            if abs((ly + 5.1) - ey) < 1.0:
                nm = [n for (ny, n) in name_labels if abs((ny - 7.3) - ey) < 1.0]
                match = f'  --> SM1 pin {t}' + (f' = {nm[0]}' if nm else '')
        print(f'  P2.{bit} (DIP40 {pin_dip[bit]}): wire ends at ({ex:7.1f},{ey:8.2f}){match}')
    else:
        print(f'  P2.{bit} (DIP40 {pin_dip[bit]}): does NOT reach the display; '
              f'net bbox {tuple(round(v) for v in bbox(segs, nets[root]["segs"]))} labels={lab}')
