#!/usr/bin/env python3
"""schem_trace.py -- turn the extracted vector geometry of the schematic into a
netlist, using the junction dots to tell a real connection from a mere crossing.

Inputs (from tools/pdf_vector.py):
    refs/_vector/segments.tsv   x1 y1 x2 y2 gray width
    refs/_vector/dots.tsv       cx cy r
    refs/_vector/labels.tsv     x y em gray font text

Usage:
    python schem_trace.py --dir refs/_vector pins          # list pin stubs
    python schem_trace.py --dir refs/_vector wires X0 X1 Y0 Y1   # dump a window
    python schem_trace.py --dir refs/_vector trace X Y     # trace from a point
    python schem_trace.py --dir refs/_vector netlist       # trace every MCU pin
"""
import argparse
import math
import os
import sys
from collections import defaultdict

TOL = 2.5          # px: endpoints closer than this are the same node
DOT_SNAP = 4.0     # px: a dot this close to a segment joins it


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
                labels.append((float(p[0]), float(p[1]), p[5]))
    return segs, dots, labels


class Graph:
    def __init__(self, segs, dots):
        self.segs = segs
        self.dots = dots
        self.parent = {}

    # ---- union-find over "node ids" -------------------------------------
    def find(self, a):
        self.parent.setdefault(a, a)
        while self.parent[a] != a:
            self.parent[a] = self.parent[self.parent[a]]
            a = self.parent[a]
        return a

    def union(self, a, b):
        ra, rb = self.find(a), self.find(b)
        if ra != rb:
            self.parent[rb] = ra

    def build(self):
        # nodes = segment endpoints, merged by proximity
        pts = []
        for i, s in enumerate(self.segs):
            pts.append((i, 0, s[0], s[1]))
            pts.append((i, 1, s[2], s[3]))
        # bucket by rounded coords for speed
        buckets = defaultdict(list)
        for (i, e, x, y) in pts:
            buckets[(round(x / TOL), round(y / TOL))].append((i, e, x, y))
        seen = {}
        for key, group in buckets.items():
            if key in seen:
                continue
            # merge neighbours (3x3) transitively -- simple approach: seed a
            # representative for each endpoint and union within neighbourhood
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    for other in buckets.get((key[0] + dx, key[1] + dy), []):
                        for g in group:
                            if math.hypot(g[2] - other[2], g[3] - other[3]) <= TOL:
                                self.union(('e', g[0], g[1]), ('e', other[0], other[1]))

        # junction dots union everything passing through them
        for (cx, cy, r) in self.dots:
            hit = []
            for i, s in enumerate(self.segs):
                if point_on_segment(cx, cy, s, tol=r + DOT_SNAP):
                    hit.append(('e', i, 0))
                    hit.append(('e', i, 1))
            for h in hit[1:]:
                self.union(hit[0], h)

    def node(self, x, y):
        best, bd = None, 1e9
        for i, s in enumerate(self.segs):
            for e, (px, py) in ((0, (s[0], s[1])), (1, (s[2], s[3]))):
                d = math.hypot(px - x, py - y)
                if d < bd:
                    bd, best = d, ('e', i, e)
                # also allow starting mid-segment
                if point_on_segment(x, y, s, tol=TOL):
                    return self.find(('e', i, 0))
        return self.find(best) if best and bd < 20 else None

    def group_members(self):
        g = defaultdict(list)
        for key in list(self.parent):
            g[self.find(key)].append(key)
        return g


def point_on_segment(px, py, s, tol=1.0):
    x1, y1, x2, y2 = s[0], s[1], s[2], s[3]
    dx, dy = x2 - x1, y2 - y1
    L2 = dx * dx + dy * dy
    if L2 == 0:
        return math.hypot(px - x1, py - y1) <= tol
    t = ((px - x1) * dx + (py - y1) * dy) / L2
    if t < -0.02 or t > 1.02:
        return False
    cx, cy = x1 + t * dx, y1 + t * dy
    return math.hypot(px - cx, py - cy) <= tol


def seg_span(g, root):
    xs, ys = [], []
    for (i, e) in [(k[1], k[2]) for k in g.parent if k[0] == 'e' and g.find(k) == root]:
        s = g.segs[i]
        xs += [s[0], s[2]]
        ys += [s[1], s[3]]
    return (min(xs), min(ys), max(xs), max(ys)) if xs else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dir', default='refs/_vector')
    ap.add_argument('cmd', choices=['pins', 'wires', 'trace', 'netlist', 'stats'])
    ap.add_argument('args', nargs='*', type=float)
    args = ap.parse_args()

    segs, dots, labels = load(args.dir)
    g = Graph(segs, dots)
    g.build()
    groups = g.group_members()

    if args.cmd == 'stats':
        print(f'segments {len(segs)}  dots {len(dots)}  labels {len(labels)}')
        horiz = [s for s in segs if abs(s[1] - s[3]) < 0.5]
        vert = [s for s in segs if abs(s[0] - s[2]) < 0.5]
        print(f'horizontal {len(horiz)}  vertical {len(vert)}  other {len(segs)-len(horiz)-len(vert)}')
        print(f'net groups: {len(set(g.find(k) for k in g.parent))}')

    elif args.cmd == 'wires':
        x0, x1, y0, y1 = args.args
        for s in sorted([s for s in segs if x0 <= s[0] <= x1 and y0 <= s[1] <= y1],
                        key=lambda s: (round(s[1], 1), s[0])):
            kind = 'H' if abs(s[1] - s[3]) < 0.5 else ('V' if abs(s[0] - s[2]) < 0.5 else 'D')
            print(f'{kind} ({s[0]:8.1f},{s[1]:8.1f}) -> ({s[2]:8.1f},{s[3]:8.1f})  w={s[5]:.2f} g={s[4]:.2f}')

    elif args.cmd == 'pins':
        # horizontal stubs: short horizontal segments, list them by y
        for s in sorted([s for s in segs if abs(s[1] - s[3]) < 0.5 and 5 < abs(s[2] - s[0]) < 60],
                        key=lambda s: (round(s[1], 1), s[0])):
            print(f'y={s[1]:8.1f}  x {s[0]:8.1f} -> {s[2]:8.1f}   len={abs(s[2]-s[0]):5.1f}')

    elif args.cmd == 'trace':
        x, y = args.args
        root = g.node(x, y)
        if root is None:
            print('no wire found near that point')
            return
        span = seg_span(g, root)
        print(f'net containing ({x},{y}): bbox {span}')
        for (lx, ly, text) in labels:
            if span and span[0] - 8 <= lx <= span[2] + 120 and span[1] - 20 <= ly <= span[3] + 20:
                print(f'   label "{text}" at ({lx:.1f},{ly:.1f})')

    elif args.cmd == 'netlist':
        for (lx, ly, text) in sorted(labels, key=lambda l: l[1]):
            root = g.node(lx + 6, ly - 8)
            if root is None:
                continue
            span = seg_span(g, root)
            print(f'{text:<10} ({lx:7.1f},{ly:7.1f})  net bbox {span}')


if __name__ == '__main__':
    main()
