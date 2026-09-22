#!/usr/bin/env python3
"""schem_net.py -- build the netlist of the schematic from the extracted vector
geometry, then answer "which MCU pin drives which L293D input".

Connectivity rules (this is the whole point -- the doc warned that automatic wire
tracing is unsafe because crossings are not marked; but they ARE marked):

  * two segments sharing an endpoint            -> connected
  * an endpoint lying on another segment        -> connected (T junction)
  * two segments crossing (both interiors)      -> connected ONLY if a junction
                                                   dot sits on the crossing

junction dots come from refs/_vector/dots.tsv (small filled discs, r ~= 1 px).

Usage:
    python schem_net.py --dir refs/_vector summary
    python schem_net.py --dir refs/_vector mcu          # MCU right-side pins -> where
    python schem_net.py --dir refs/_vector net N        # detail of net N
"""
import argparse
import math
import os
from collections import defaultdict

TOL = 2.0        # px, endpoint coincidence
DOT_TOL = 2.5    # px, dot radius slack
LABEL_TOL = 14.0  # px, how close a label must sit to a wire to name it


def load(d):
    segs, dots, labels = [], [], []
    with open(os.path.join(d, 'segments.tsv'), encoding='utf-8') as fh:
        next(fh)
        for line in fh:
            p = line.rstrip('\n').split('\t')
            if len(p) >= 6:
                segs.append(tuple(float(v) for v in p[:6]))
    with open(os.path.join(d, 'dots.tsv'), encoding='utf-8') as fh:
        next(fh)
        for line in fh:
            p = line.rstrip('\n').split('\t')
            if len(p) >= 3:
                dots.append(tuple(float(v) for v in p[:3]))
    with open(os.path.join(d, 'labels.tsv'), encoding='utf-8') as fh:
        next(fh)
        for line in fh:
            p = line.rstrip('\n').split('\t')
            if len(p) >= 6:
                labels.append((float(p[0]), float(p[1]), float(p[2]), p[5]))
    return segs, dots, labels


def point_seg_dist(px, py, s):
    """Distance from point to segment, plus the parameter t along it."""
    x1, y1, x2, y2 = s[0], s[1], s[2], s[3]
    dx, dy = x2 - x1, y2 - y1
    L2 = dx * dx + dy * dy
    if L2 == 0:
        return math.hypot(px - x1, py - y1), 0.0
    t = ((px - x1) * dx + (py - y1) * dy) / L2
    tc = min(1.0, max(0.0, t))
    cx, cy = x1 + tc * dx, y1 + tc * dy
    return math.hypot(px - cx, py - cy), t


class Netlist:
    def __init__(self, segs, dots):
        self.segs = segs
        self.dots = dots
        self.parent = {}

    def find(self, a):
        self.parent.setdefault(a, a)
        r = a
        while self.parent[r] != r:
            r = self.parent[r]
        while self.parent[a] != r:
            self.parent[a], a = r, self.parent[a]
        return r

    def union(self, a, b):
        ra, rb = self.find(a), self.find(b)
        if ra != rb:
            self.parent[rb] = ra

    def _dot_near(self, x, y, tol=3.0):
        for (cx, cy, r) in self.dots:
            if math.hypot(cx - x, cy - y) <= r + tol:
                return True
        return False

    def build(self):
        n = len(self.segs)
        ends = []
        for i, s in enumerate(self.segs):
            for e, (x, y) in ((0, (s[0], s[1])), (1, (s[2], s[3]))):
                ends.append((i, e, x, y))
                self.parent[('e', i, e)] = ('e', i, e)
            # A segment IS one conductor: its two ends are the same net. Without
            # this, find(e0) and find(e1) land on different roots and every net
            # gets split apart when grouped by find(e0).
            self.union(('e', i, 0), ('e', i, 1))

        # 1) endpoints that coincide
        for a in range(len(ends)):
            ia, ea, xa, ya = ends[a]
            for b in range(a + 1, len(ends)):
                ib, eb, xb, yb = ends[b]
                if ia == ib:
                    continue
                if abs(xa - xb) <= TOL and abs(ya - yb) <= TOL:
                    self.union(('e', ia, ea), ('e', ib, eb))

        # 2) T junctions: an endpoint lying strictly inside another segment.
        #    A junction dot is REQUIRED.  Without this guard a component symbol
        #    whose outline passes through its own pin ends (the 10K resistor
        #    network RN is drawn exactly like that) would short every pin of the
        #    part together.
        for (i, e, x, y) in ends:
            if not self._dot_near(x, y):
                continue
            for j, s in enumerate(self.segs):
                if i == j:
                    continue
                dist, t = point_seg_dist(x, y, s)
                if dist <= TOL and 0.02 < t < 0.98:
                    self.union(('e', i, e), ('e', j, 0))

        # 3) junction dots join everything passing through them
        for (cx, cy, r) in self.dots:
            hit = []
            for i, s in enumerate(self.segs):
                dist, t = point_seg_dist(cx, cy, s)
                if dist <= r + DOT_TOL:
                    hit += [('e', i, 0), ('e', i, 1)]
            if len(hit) > 1:
                for h in hit[1:]:
                    self.union(hit[0], h)

    # ---------------------------------------------------------------- queries
    def nets(self):
        out = defaultdict(lambda: {'segs': [], 'ends': []})
        for i, s in enumerate(self.segs):
            r = self.find(('e', i, 0))
            out[r]['segs'].append(i)
        for key in list(self.parent):
            out[self.find(key)]['ends'].append(key)
        return out

    def net_of_point(self, x, y, maxd=6.0):
        best, bd = None, 1e9
        for i, s in enumerate(self.segs):
            dist, t = point_seg_dist(x, y, s)
            if dist < bd:
                bd, best = dist, self.find(('e', i, 0))
        return best if bd <= maxd else None

    def free_ends(self, root, nets):
        """Endpoints that touch only one segment -> real connection points."""
        cnt = defaultdict(int)
        for (i, e) in [(k[1], k[2]) for k in nets[root]['ends'] if k[0] == 'e']:
            cnt[(i, e)] += 1
        # count how many segments have an endpoint at this location
        loc = []
        segs = nets[root]['segs']
        for (i, e) in cnt:
            x, y = (self.segs[i][0], self.segs[i][1]) if e == 0 else (self.segs[i][2], self.segs[i][3])
            shared = 0
            for j in segs:
                for (jx, jy) in ((self.segs[j][0], self.segs[j][1]), (self.segs[j][2], self.segs[j][3])):
                    if abs(jx - x) <= TOL and abs(jy - y) <= TOL:
                        shared += 1
            if shared <= 1:
                loc.append((x, y))
        return loc

    def labels_on(self, root, nets, labels):
        segs = nets[root]['segs']
        out = []
        for (lx, ly, em, text) in labels:
            if not text.strip() or not any(c.isalnum() for c in text):
                continue
            for j in segs:
                dist, t = point_seg_dist(lx + em * 0.6, ly - em * 0.35, self.segs[j])
                if dist <= LABEL_TOL:
                    out.append((text, lx, ly))
                    break
        return out

    def labels_near(self, x, y, labels, tol=30.0):
        """Labels whose text box sits near a point (used to name a far end)."""
        out = []
        for (lx, ly, em, text) in labels:
            if not text.strip():
                continue
            cx, cy = lx + em * 0.6, ly - em * 0.35
            if abs(cx - x) <= tol and abs(cy - y) <= tol:
                out.append(text)
        return out


def bbox(segs, idxs):
    xs, ys = [], []
    for i in idxs:
        s = segs[i]
        xs += [s[0], s[2]]
        ys += [s[1], s[3]]
    return min(xs), min(ys), max(xs), max(ys)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dir', default='refs/_vector')
    ap.add_argument('cmd', choices=['summary', 'mcu', 'net', 'pins', 'stubs', 'region', 'nets', 'point'])
    ap.add_argument('args', nargs='*')
    args = ap.parse_args()

    segs, dots, labels = load(args.dir)
    nl = Netlist(segs, dots)
    nl.build()
    nets = nl.nets()
    roots = sorted(nets, key=lambda r: -len(nets[r]['segs']))

    if args.cmd == 'summary':
        print(f'segments={len(segs)} dots={len(dots)} labels={len(labels)}')
        print(f'nets={len(roots)}')
        multi = [r for r in roots if len(nets[r]['segs']) > 1]
        print(f'nets with >1 segment: {len(multi)}')
        for r in multi[:12]:
            bb = bbox(segs, nets[r]['segs'])
            labs = [t for (t, _, _) in nl.labels_on(r, nets, labels)]
            print(f'  net {r}  segs={len(nets[r]["segs"]):>3}  bbox=({bb[0]:.0f},{bb[1]:.0f})-({bb[2]:.0f},{bb[3]:.0f})  labels={labs[:8]}')

    elif args.cmd == 'mcu':
        # MCU right-side pins: horizontal segments from x=2050.6 to x=2124.8
        pins = []
        for i, s in enumerate(segs):
            if abs(s[1] - s[3]) < 0.5 and abs(min(s[0], s[2]) - 2050.55) < 1.5 and abs(max(s[0], s[2]) - 2124.75) < 1.5:
                pins.append((s[1], i))
        pins.sort()
        print(f'MCU right-side pins found: {len(pins)}')
        for (y, i) in pins:
            root = nl.find(('e', i, 0))
            bb = bbox(segs, nets[root]['segs'])
            labs = [t for (t, _, _) in nl.labels_on(root, nets, labels)]
            ends = nl.free_ends(root, nets)
            ends = sorted([e for e in ends if not (abs(e[0] - 2124.75) < 3)])
            print(f'  y={y:8.1f}  segs={len(nets[root]["segs"]):>3}  '
                  f'bbox=({bb[0]:7.1f},{bb[1]:7.1f})-({bb[2]:7.1f},{bb[3]:7.1f})  '
                  f'labels={labs}  far_ends={[(round(a),round(b)) for a,b in ends][:6]}')

    elif args.cmd == 'pins':
        # every short horizontal stub anywhere (candidate component pins)
        for i, s in enumerate(sorted(segs, key=lambda s: (round(s[1], 1), s[0]))):
            L = abs(s[2] - s[0])
            if abs(s[1] - s[3]) < 0.5 and 20 < L < 120:
                print(f'y={s[1]:8.1f}  x {min(s[0],s[2]):8.1f} -> {max(s[0],s[2]):8.1f}  len={L:6.1f}')

    elif args.cmd == 'stubs':
        # every pin-like horizontal stub anywhere: its net and where it goes
        seen = set()
        for i, s in enumerate(segs):
            L = abs(s[2] - s[0])
            if abs(s[1] - s[3]) > 0.5 or not (55 < L < 95):
                continue
            root = nl.find(('e', i, 0))
            if root in seen:
                continue
            seen.add(root)
            bb = bbox(segs, nets[root]['segs'])
            ends = sorted(nl.free_ends(root, nets))
            lab = [t for (t, _, _) in nl.labels_on(root, nets, labels)]
            print(f'y={s[1]:8.1f}  x {min(s[0],s[2]):7.1f}->{max(s[0],s[2]):7.1f}  '
                  f'net_segs={len(nets[root]["segs"]):>3}  bbox=({bb[0]:.0f},{bb[1]:.0f})-({bb[2]:.0f},{bb[3]:.0f})')
            print(f'          net labels: {lab}')
            for (ex, ey) in ends:
                near = nl.labels_near(ex, ey, labels, 26)
                print(f'          far end ({ex:7.1f},{ey:7.1f})  near: {near}')

    elif args.cmd == 'region':
        x0, y0, x1, y1 = (float(v) for v in args.args)
        print(f'--- labels in ({x0},{y0})-({x1},{y1}) ---')
        for (lx, ly, em, text) in sorted(labels, key=lambda l: (l[1], l[0])):
            if x0 <= lx <= x1 and y0 <= ly <= y1:
                print(f'  ({lx:7.1f},{ly:7.1f}) em={em:.2f}  "{text}"')
        print(f'--- pin stubs in region ---')
        for i, s in enumerate(segs):
            if abs(s[1] - s[3]) > 0.5:
                continue
            if not (55 < abs(s[2] - s[0]) < 95):
                continue
            if x0 <= min(s[0], s[2]) and max(s[0], s[2]) <= x1 and y0 <= s[1] <= y1:
                print(f'  y={s[1]:8.1f}  x {min(s[0],s[2]):8.1f} -> {max(s[0],s[2]):8.1f}')

    elif args.cmd == 'nets':
        # every net with more than one segment, with labels and named far ends
        for root in sorted(nets, key=lambda r: bbox(segs, nets[r]['segs'])[0]):
            if len(nets[root]['segs']) < 2:
                continue
            bb = bbox(segs, nets[root]['segs'])
            lab = [t for (t, _, _) in nl.labels_on(root, nets, labels)]
            print(f'NET {root}  segs={len(nets[root]["segs"]):>3}  '
                  f'bbox=({bb[0]:7.1f},{bb[1]:7.1f})-({bb[2]:7.1f},{bb[3]:7.1f})  labels={lab}')
            for (ex, ey) in sorted(nl.free_ends(root, nets)):
                near = nl.labels_near(ex, ey, labels, 30)
                if near:
                    print(f'      end ({ex:7.1f},{ey:7.1f})  near {near}')

    elif args.cmd == 'point':
        x, y = (float(v) for v in args.args)
        root = nl.net_of_point(x, y, maxd=8.0)
        if root is None:
            # fall back: nearest net by dot
            print('no net within 8 px')
            return
        print(f'net {root}:')
        for i in nets[root]['segs']:
            s = segs[i]
            print(f'   ({s[0]:8.1f},{s[1]:8.1f}) -> ({s[2]:8.1f},{s[3]:8.1f})')
        print('  labels:', [t for (t, _, _) in nl.labels_on(root, nets, labels)])
        for (ex, ey) in sorted(nl.free_ends(root, nets)):
            print(f'  end ({ex:7.1f},{ey:7.1f})  near {nl.labels_near(ex, ey, labels, 30)}')

    elif args.cmd == 'net':
        root = list(nets)[int(args.args[0])] if args.args and args.args[0].isdigit() else None
        if root is None:
            print('give a net root id (see summary/mcu)')
            return
        for i in nets[root]['segs']:
            s = segs[i]
            print(f'  ({s[0]:8.1f},{s[1]:8.1f}) -> ({s[2]:8.1f},{s[3]:8.1f})')
        print('  labels:', nl.labels_on(root, nets, labels))


if __name__ == '__main__':
    main()
