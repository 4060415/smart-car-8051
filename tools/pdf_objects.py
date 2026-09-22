#!/usr/bin/env python3
"""pdf_objects.py -- print each PDF object's dictionary header (and stream
length), to understand the file's structure: catalog, pages, resources, fonts.

Usage: python pdf_objects.py <file.pdf> [--head N]
"""
import argparse
import re
import sys

OBJ_RE = re.compile(rb'(\d+)\s+0\s+obj')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('pdf')
    ap.add_argument('--head', type=int, default=400)
    ap.add_argument('--grep', default=None)
    args = ap.parse_args()

    data = open(args.pdf, 'rb').read()
    for m in OBJ_RE.finditer(data):
        num = int(m.group(1))
        seg = data[m.end():m.end() + args.head]
        cut = seg.find(b'stream')
        if cut != -1 and cut < 300:
            seg = seg[:cut]
        text = ' '.join(seg.decode('latin-1').replace('\r', ' ').replace('\n', ' ').split())
        line = f'{num:>3}: {text[:230]}'
        if args.grep and args.grep.lower() not in line.lower():
            continue
        print(line)

    print('--- searching for font/text-marking resources ---', file=sys.stderr)
    for pat in (b'/Font', b'/BaseFont', b'/ToUnicode', b'/Type1', b'/TrueType',
                b'/Type3', b'/Type0', b'/Subtype /Image', b'BT', b'Tj', b'TJ'):
        print(f'  {pat.decode():<18} count={data.count(pat)}', file=sys.stderr)
    print(f'  {"Number of Pages":<18} count={len(re.findall(rb"/Type\s*/Page[^s]", data))}', file=sys.stderr)


if __name__ == '__main__':
    main()
