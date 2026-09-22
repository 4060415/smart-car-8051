#!/usr/bin/env python3
"""pdf_vector.py -- recover the exact vector geometry and text of a schematic
PDF page, expressed in the pixel space of the rendered PNG.

WHY THIS EXISTS
    docs\\参考资料挖掘结果.md concluded the schematic has no fonts at all ("文字
    转轮廓") because a grep for "/Font" over the raw bytes returns 0.  That is
    wrong: the font dictionaries live inside COMPRESSED object streams
    (/Type/ObjStm), and the page content streams 14..21 contain real text
    operators, e.g.

        BT /TT2 1 Tf 0 4.4119 -4.4102 0 587.1 94.1306 Tm 0 Tc 0 Tw (C13)Tj ET
        BT ... (Z2)Tj T* -.0104 Tc [(11.)-18.8(05)13.6(92M)]TJ ET

    So every label can be read as text WITH its exact position, and every wire
    is a stroked line segment with exact endpoints.  This beats both OCR and
    squinting at pixels.

Outputs (TSV; coordinates in rendered-PNG pixels):
    segments.tsv  x1 y1 x2 y2 gray width
    dots.tsv      cx cy r            junction dots (small filled circles)
    labels.tsv    x y em gray font text
    fills.tsv     x0 y0 x1 y1 npts gray

Usage:
    python pdf_vector.py <file.pdf> --out refs/_vector
    python pdf_vector.py <file.pdf> --out refs/_vector --calibrate refs/schem_words.tsv
"""
import argparse
import math
import os
import re
import statistics
import sys
import zlib

OBJ_RE = re.compile(rb'(\d+)\s+0\s+obj(.*?)endobj', re.S)
STREAM_RE = re.compile(rb'stream\r?\n(.*?)\r?\nendstream', re.S)
NUMBER_RE = re.compile(rb'[+-]?(?:\d+\.?\d*|\.\d+)')
DELIM = b'()<>[]{}/%'
WHITE = b' \t\r\n\f\x00'


# --------------------------------------------------------------- PDF objects

def load_objects(path):
    """Return (streams, dicts): decoded stream bodies, and raw dict bodies."""
    data = open(path, 'rb').read()
    streams, dicts = {}, {}
    for m in OBJ_RE.finditer(data):
        num = int(m.group(1))
        body = m.group(2)
        sm = STREAM_RE.search(body)
        if sm:
            raw = sm.group(1)
            if b'FlateDecode' in body[:sm.start()]:
                try:
                    raw = zlib.decompress(raw)
                except Exception:
                    continue
            streams[num] = raw
        else:
            dicts[num] = body
    return data, streams, dicts


# ----------------------------------------------------------------- tokenizer

def tokenize(data):
    i, n = 0, len(data)
    while i < n:
        c = data[i:i + 1]
        if c in WHITE:
            i += 1
            continue
        if c == b'%':
            j = data.find(b'\n', i)
            i = n if j == -1 else j + 1
            continue
        if c == b'(':
            depth, j, buf = 1, i + 1, bytearray()
            while j < n and depth:
                ch = data[j:j + 1]
                if ch == b'\\':
                    nxt = data[j + 1:j + 2]
                    simple = {b'n': 10, b'r': 13, b't': 9, b'b': 8, b'f': 12}
                    if nxt in simple:
                        buf.append(simple[nxt]); j += 2
                    elif nxt.isdigit():
                        k, digs = j + 1, b''
                        while k < n and len(digs) < 3 and data[k:k + 1].isdigit():
                            digs += data[k:k + 1]; k += 1
                        buf.append(int(digs, 8) & 0xFF); j = k
                    else:
                        buf += nxt; j += 2
                    continue
                if ch == b'(':
                    depth += 1
                elif ch == b')':
                    depth -= 1
                    if depth == 0:
                        j += 1
                        break
                buf += ch
                j += 1
            yield ('str', bytes(buf))
            i = j
            continue
        if c == b'<' and data[i + 1:i + 2] != b'<':
            j = data.find(b'>', i)
            hexs = re.sub(rb'[^0-9A-Fa-f]', b'', data[i + 1:j])
            if len(hexs) % 2:
                hexs += b'0'
            yield ('str', bytes.fromhex(hexs.decode()))
            i = j + 1
            continue
        if c in b'<>[]':
            two = data[i:i + 2]
            if two in (b'<<', b'>>'):
                yield ('kw', two); i += 2
            else:
                yield ('kw', data[i:i + 1]); i += 1
            continue
        if c == b'/':
            j = i + 1
            while j < n and data[j:j + 1] not in WHITE and data[j:j + 1] not in DELIM:
                j += 1
            yield ('name', data[i + 1:j])
            i = j
            continue
        m = NUMBER_RE.match(data, i)
        if m:
            yield ('num', float(m.group()))
            i = m.end()
            continue
        j = i
        while j < n and data[j:j + 1] not in WHITE and data[j:j + 1] not in DELIM:
            j += 1
        yield ('kw', data[i:j] if j > i else data[i:i + 1])
        i = j if j > i else i + 1


# ------------------------------------------------------------------ matrices

def mat_mul(m, n):
    a, b, c, d, e, f = m
    a2, b2, c2, d2, e2, f2 = n
    return (a * a2 + b * c2, a * b2 + b * d2,
            c * a2 + d * c2, c * b2 + d * d2,
            e * a2 + f * c2 + e2, e * b2 + f * d2 + f2)


def apply(m, x, y):
    a, b, c, d, e, f = m
    return (a * x + c * y + e, b * x + d * y + f)


# -------------------------------------------------------------------- extract

PAINT = (b'S', b's', b'f', b'F', b'f*', b'B', b'B*', b'b', b'b*', b'n')
STROKE = (b'S', b's', b'B', b'B*', b'b', b'b*')
FILL = (b'f', b'F', b'f*', b'B', b'B*', b'b', b'b*')


def extract(objs, contents):
    segs, dots, labels, fills = [], [], [], []
    ctm = (1, 0, 0, 1, 0, 0)
    gstack = []
    gs = {'w': 1.0, 'gray': 0.0, 'font': ''}
    tm = tlm = (1, 0, 0, 1, 0, 0)
    tl = 0.0

    for cid in contents:
        data = objs.get(cid)
        if data is None:
            continue
        pending, path, start = [], [], None

        for kind, val in tokenize(data):
            # '[' , ']' , '<<' , '>>' are NOT operators -- they are structural
            # tokens inside an operand list.  Treating ']' as an operator used to
            # wipe `pending` (the reset at the bottom of this loop), which threw
            # away every string of a "[...]TJ" array: i.e. ALL kerned text was
            # silently dropped (VCCBAT/USB5V, EA/VPP, RXD(P30), the L293D pin
            # names INPUT1..OUTPUT4, the title block...).  Only simple "(x)Tj"
            # text survived.
            if kind != 'kw' or val in (b'[', b']', b'<<', b'>>'):
                pending.append((kind, val))
                continue
            op = val
            nums = [v for (k, v) in pending if k == 'num']
            strs = [v for (k, v) in pending if k == 'str']
            names = [v for (k, v) in pending if k == 'name']

            if op == b'q':
                gstack.append((ctm, dict(gs)))
            elif op == b'Q':
                if gstack:
                    ctm, g = gstack.pop()
                    gs = dict(g)
            elif op == b'cm' and len(nums) >= 6:
                ctm = mat_mul(tuple(nums[-6:]), ctm)
            elif op == b'w' and nums:
                gs['w'] = nums[-1]
            elif op in (b'g', b'G') and nums:
                gs['gray'] = nums[-1]
            elif op in (b'rg', b'RG') and len(nums) >= 3:
                gs['gray'] = sum(nums[-3:]) / 3.0
            elif op == b'Tf':
                gs['font'] = names[-1].decode('latin-1') if names else ''
            elif op == b'BT':
                tm = tlm = (1, 0, 0, 1, 0, 0)
            elif op == b'Tm' and len(nums) >= 6:
                tm = tlm = tuple(nums[-6:])
            elif op == b'TD' and len(nums) >= 2:
                tlm = mat_mul((1, 0, 0, 1, nums[-2], nums[-1]), tlm)
                tm = tlm
                tl = -nums[-1]
            elif op == b'Td' and len(nums) >= 2:
                tlm = mat_mul((1, 0, 0, 1, nums[-2], nums[-1]), tlm)
                tm = tlm
            elif op == b'TL' and nums:
                tl = nums[-1]
            elif op == b'T*':
                tlm = mat_mul((1, 0, 0, 1, 0, -tl), tlm)
                tm = tlm
            elif op in (b'Tj', b"'", b'"', b'TJ'):
                text = b''.join(strs)
                if text:
                    m = mat_mul(tm, ctm)
                    ox, oy = apply(m, 0, 0)
                    em = math.hypot(m[0], m[1])
                    labels.append((ox, oy, em, gs['gray'], gs['font'],
                                   text.decode('latin-1')))
            elif op == b'm' and len(nums) >= 2:
                start = (nums[-2], nums[-1])
                path = [start]
            elif op == b'l' and len(nums) >= 2:
                path.append((nums[-2], nums[-1]))
            elif op in (b'c', b'v', b'y') and len(nums) >= 4:
                path.append((nums[-2], nums[-1]))
            elif op == b're' and len(nums) >= 4:
                x, y, w, h = nums[-4:]
                start = (x, y)
                path = [(x, y), (x + w, y), (x + w, y + h), (x, y + h), (x, y)]
            elif op == b'h' and start:
                path.append(start)
            elif op in PAINT:
                dev = [apply(ctm, x, y) for (x, y) in path]
                if dev and op in STROKE:
                    for i in range(len(dev) - 1):
                        segs.append((dev[i][0], dev[i][1], dev[i + 1][0],
                                     dev[i + 1][1], gs['gray'], gs['w']))
                if dev and op in FILL:
                    xs = [p[0] for p in dev]
                    ys = [p[1] for p in dev]
                    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
                    fills.append((x0, y0, x1, y1, len(dev), gs['gray']))
                    w, h = x1 - x0, y1 - y0
                    if 0.5 < w < 9 and 0.5 < h < 9 and abs(w - h) < 3:
                        dots.append(((x0 + x1) / 2, (y0 + y1) / 2, (w + h) / 4))
                path, start = [], None
            pending = []
    return segs, dots, labels, fills


# --------------------------------------------------------------------- raster

def make_raster(mb, rotate, png_w, png_h):
    """PDF user space (y UP, origin bottom-left) -> PNG pixels (y DOWN).

    /Rotate 90 turns the sheet clockwise, so the user-space LEFT edge becomes
    the displayed TOP edge and the user-space BOTTOM edge becomes the LEFT one:
        u = y - y0      v = x - x0
    (verified against the OCR bounding boxes: label "P02" sits at user
    (167.1, 396.1) and its OCR box starts at PNG x=1999, y=828 with a 16 px cap
    height -> 396.1*5.0475 = 1999 and 167.1*5.0475 = 843 ~= 828+16.)
    """
    w, h = mb[2] - mb[0], mb[3] - mb[1]
    dw, dh = (h, w) if rotate in (90, 270) else (w, h)
    sx, sy = png_w / dw, png_h / dh

    def ras(x, y):
        if rotate == 90:          # clockwise: left edge -> top
            dx, dy = y - mb[1], x - mb[0]
        elif rotate == 180:
            dx, dy = mb[2] - x, y - mb[1]
        elif rotate == 270:       # counter-clockwise: left edge -> bottom
            dx, dy = mb[3] - y, mb[2] - x
        else:
            dx, dy = x - mb[0], mb[3] - y
        return dx * sx, dy * sy
    return ras


def calibrate(labels, tsv_path):
    """Cross-check the coordinate mapping against the OCR bounding boxes."""
    rows = []
    with open(tsv_path, encoding='utf-8') as fh:
        next(fh)
        for line in fh:
            p = line.rstrip('\n').split('\t')
            if len(p) >= 7:
                rows.append((p[0], float(p[5]), float(p[6])))
    ocr = {}
    for text, cx, cy in rows:
        ocr.setdefault(text.strip().lower(), []).append((cx, cy))

    for rot in (0, 90, 180, 270):
        ras = make_raster([0, 0, 595.22, 842], rot, 4250, 3004)
        errs = []
        for (ox, oy, em, g, f, text) in labels:
            key = text.strip().lower()
            if key in ocr:
                x, y = ras(ox, oy)
                cx, cy = min(ocr[key], key=lambda c: (c[0] - x) ** 2 + (c[1] - y) ** 2)
                errs.append(math.hypot(cx - x, cy - y))
        if errs:
            print(f'  rotate {rot:>3}: matched {len(errs):>3} labels, '
                  f'median error {statistics.median(errs):7.1f} px, '
                  f'mean {statistics.mean(errs):7.1f} px')
        else:
            print(f'  rotate {rot:>3}: no matches')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('pdf')
    ap.add_argument('--out', required=True)
    ap.add_argument('--png-width', type=int, default=4250)
    ap.add_argument('--png-height', type=int, default=3004)
    ap.add_argument('--media', default='0,0,595.22,842')
    ap.add_argument('--rotate', type=int, default=90)
    ap.add_argument('--calibrate', default=None)
    args = ap.parse_args()

    _, objs, dicts = load_objects(args.pdf)
    page = dicts.get(12, b'').decode('latin-1')
    m = re.search(r'/Contents\s*\[([^\]]*)\]', page)
    contents = [int(v) for v in re.findall(r'(\d+)\s+0\s+R', m.group(1))] if m else [14]
    print(f'content streams: {contents}')

    segs, dots, labels, fills = extract(objs, contents)
    print(f'segments={len(segs)}  dots={len(dots)}  labels={len(labels)}  fills={len(fills)}')

    if args.calibrate:
        print('calibration against OCR bounding boxes:')
        calibrate(labels, args.calibrate)

    mb = [float(v) for v in args.media.split(',')]
    ras = make_raster(mb, args.rotate, args.png_width, args.png_height)
    os.makedirs(args.out, exist_ok=True)

    def wr(name, header, rows):
        p = os.path.join(args.out, name)
        with open(p, 'w', encoding='utf-8') as fh:
            fh.write(header + '\n')
            for r in rows:
                fh.write('\t'.join(str(v) for v in r) + '\n')
        print(f'  {p}  ({len(rows)} rows)')

    def clean(s):
        # TSV safety: no tabs / CR / LF inside the text field
        return s.replace('\r', '\\r').replace('\n', '\\n').replace('\t', ' ')

    wr('segments.tsv', 'x1\ty1\tx2\ty2\tgray\twidth',
       [[round(ras(s[0], s[1])[0], 2), round(ras(s[0], s[1])[1], 2),
         round(ras(s[2], s[3])[0], 2), round(ras(s[2], s[3])[1], 2),
         round(s[4], 3), s[5]] for s in segs])
    wr('dots.tsv', 'cx\tcy\tr',
       [[round(ras(d[0], d[1])[0], 2), round(ras(d[0], d[1])[1], 2), round(d[2], 2)]
        for d in dots])
    wr('labels.tsv', 'x\ty\tem\tgray\tfont\ttext',
       [[round(ras(l[0], l[1])[0], 2), round(ras(l[0], l[1])[1], 2),
         round(l[2], 3), round(l[3], 3), l[4], clean(l[5])] for l in labels])
    wr('fills.tsv', 'x0\ty0\tx1\ty1\tnpts\tgray',
       [[round(ras(f[0], f[1])[0], 2), round(ras(f[0], f[1])[1], 2),
         round(ras(f[2], f[3])[0], 2), round(ras(f[2], f[3])[1], 2),
         f[4], round(f[5], 3)] for f in fills])


if __name__ == '__main__':
    main()
