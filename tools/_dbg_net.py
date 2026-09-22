import sys
sys.path.insert(0, 'tools')
from schem_net import load, Netlist, point_seg_dist

segs, dots, labels = load('refs/_vector')
nl = Netlist(segs, dots)
nl.build()

targets = []
for i, s in enumerate(segs):
    if abs(s[3] - 1033.2) < 0.5 and abs(s[1] - 1033.2) < 0.5:
        targets.append(i)
print('segments on y=1033.2:', targets)
for i in targets:
    print(f'  seg {i}: {segs[i]}  root={nl.find(("e", i, 0))} / {nl.find(("e", i, 1))}')

print()
print('dots near (2124.75,1033.2):')
for d in dots:
    if abs(d[0] - 2124.75) < 6 and abs(d[1] - 1033.2) < 6:
        print('  ', d)

print()
print('endpoint-coincidence check:')
for a in targets:
    for e in (0, 1):
        pa = (segs[a][0], segs[a][1]) if e == 0 else (segs[a][2], segs[a][3])
        for b in targets:
            if a == b:
                continue
            for f in (0, 1):
                pb = (segs[b][0], segs[b][1]) if f == 0 else (segs[b][2], segs[b][3])
                if abs(pa[0] - pb[0]) <= 2 and abs(pa[1] - pb[1]) <= 2:
                    print(f'  seg{a}.e{e} {pa}  <->  seg{b}.e{f} {pb}')
