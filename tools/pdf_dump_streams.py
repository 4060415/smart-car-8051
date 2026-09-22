#!/usr/bin/env python3
"""pdf_dump_streams.py -- decompress every stream in a PDF and dump the drawing
operators, so a vector schematic (text-outlined, no fonts) can be analysed
geometrically instead of by squinting at a raster.

Usage:
    python pdf_dump_streams.py <file.pdf> [--out DIR] [--max-ops N]

For each stream it writes <DIR>/stream_<n>.txt with one operator per line, and
prints a summary: stream sizes, operator histogram, and the graphics state
transforms (cm) encountered.
"""
import argparse
import collections
import os
import re
import sys
import zlib

OBJ_RE = re.compile(rb'(\d+)\s+0\s+obj(.*?)endobj', re.S)
STREAM_RE = re.compile(rb'stream\r?\n(.*?)\r?\nendstream', re.S)


def extract_streams(data):
    out = []
    for m in OBJ_RE.finditer(data):
        num = int(m.group(1))
        body = m.group(2)
        sm = STREAM_RE.search(body)
        if not sm:
            continue
        raw = sm.group(1)
        header = body[:sm.start()]
        if b'FlateDecode' in header:
            try:
                raw = zlib.decompress(raw)
            except Exception as exc:  # noqa: BLE001
                print(f'  ! obj {num}: inflate failed: {exc}', file=sys.stderr)
                continue
        out.append((num, header, raw))
    return out


def histogram(raw):
    """Rough operator histogram: tokenise loosely and count known operators."""
    ops = collections.Counter()
    text = raw.decode('latin-1')
    for tok in re.findall(r'(?m)(?<![A-Za-z0-9])([A-Za-z\'"*]+)(?![A-Za-z0-9])', text):
        ops[tok] += 1
    return ops


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('pdf')
    ap.add_argument('--out', default=None)
    ap.add_argument('--max-ops', type=int, default=0)
    args = ap.parse_args()

    data = open(args.pdf, 'rb').read()
    streams = extract_streams(data)
    print(f'{os.path.basename(args.pdf)}: {len(data)} bytes, {len(streams)} decoded streams')

    outdir = args.out or os.path.join(os.path.dirname(os.path.abspath(args.pdf)), '_pdf_streams')
    os.makedirs(outdir, exist_ok=True)

    for num, header, raw in streams:
        hdr = header.strip().replace(b'\r', b' ').replace(b'\n', b' ')[:100]
        ops = histogram(raw)
        interesting = {k: v for k, v in ops.items()
                       if k in ('m', 'l', 're', 'c', 'v', 'y', 'S', 's', 'f', 'F', 'f*',
                                'B', 'b', 'W', 'n', 'cm', 'q', 'Q', 'w', 'J', 'j', 'd',
                                'RG', 'rg', 'G', 'g', 'BT', 'ET', 'Tj', 'TJ', 'Do', 'sh')}
        path_ops = sum(v for k, v in interesting.items()
                       if k in ('m', 'l', 're', 'c', 'v', 'y', 'S', 's', 'f', 'F', 'f*', 'B', 'b'))
        print(f'  obj {num:>3}  {len(raw):>8} B  path-ops={path_ops:>6}  {interesting}')
        path = os.path.join(outdir, f'stream_{num:03d}.txt')
        with open(path, 'w', encoding='utf-8') as fh:
            fh.write(raw.decode('latin-1'))
    print(f'raw streams written to {outdir}')


if __name__ == '__main__':
    main()
