#!/usr/bin/env python3
"""
lst2hex.py -- turn an A51 assembly listing (.LST) directly into an Intel HEX file.

WHY THIS EXISTS
---------------
The installed Keil toolchain is the **Eval** edition. Its linker (BL51) refuses to
link programs larger than 0800H = 2048 bytes:

    *** FATAL ERROR L250: CODE SIZE LIMIT IN RESTRICTED VERSION EXCEEDED

The A51 *assembler* has no such limit (verified: it assembles a 2600-byte probe
fine). The innovation feature (teaching / playback, blocks 7 and 8) needs roughly
+500 bytes, so the project would exceed 2048 and BL51 would stop building it.

Because car_asm.asm is a **single absolute module** (ORG-based, no EXTRN/PUBLIC),
A51 already resolves every address, and the listing contains the final object
bytes. So the link step can be replaced by this converter -- no licence, no
new toolchain, no source changes.

VALIDATION
----------
Never trust this tool blindly. For any build that BL51 *can* link, compare:

    python tools/lst2hex.py firmware/car/car_asm.LST out.hex
    python tools/compare_hex.py out.hex firmware/car/car_asm.hex

The two images must be identical byte for byte. That is the regression test for
this converter (see docs for the recorded result).

LISTING FORMAT (A51 V8.01)
--------------------------
Header:      LOC  OBJ            LINE     SOURCE
Code line:   07C3 039F250D       2255                 DB  DISP_0, ...
Wrapped:     07C7 9949                    <- same LOC+OBJ shape, no LINE/SOURCE
Label only:  07C3                2254     GEARTAB:
Note object bytes are written **contiguously** (no spaces between bytes), and
A51 wraps at 4 bytes per line. Therefore: any line whose first 4 characters are
hex followed by a space is an object-code line -- everything else is ignored.

Usage:
    python lst2hex.py <input.LST> [output.hex]

Keep this file ASCII-only (the Windows console here is GBK).
"""
import re
import sys

# "^LLLL HH...H"  -- 4 hex address, one space, then a run of hex bytes (may be empty)
LOC_RE = re.compile(r'^([0-9A-F]{4}) ([0-9A-F]*)(?: |$)')


def parse_lst(path):
    """Return {address: byte} plus some stats."""
    with open(path, 'rb') as fh:
        text = fh.read().decode('latin-1')

    image = {}
    collisions = 0
    code_lines = 0
    for lineno, line in enumerate(text.splitlines(), 1):
        m = LOC_RE.match(line)
        if not m:
            continue
        obj = m.group(2)
        if len(obj) % 2:
            raise SystemExit('odd-length object field on line %d: %r' % (lineno, line[:80]))
        if not obj:
            continue                      # label-only / ORG line: no bytes
        code_lines += 1
        addr = int(m.group(1), 16)
        for i in range(0, len(obj), 2):
            a = addr + i // 2
            b = int(obj[i:i + 2], 16)
            if a in image and image[a] != b:
                collisions += 1
            image[a] = b
    return image, code_lines, collisions


def blank_ranges(image):
    """Contiguous gaps between the lowest and highest emitted address."""
    addrs = sorted(image)
    gaps = []
    for lo, hi in zip(addrs, addrs[1:]):
        if hi != lo + 1:
            gaps.append((lo + 1, hi - 1, hi - lo - 1))
    return gaps


def to_intel_hex(image, width=16):
    out = []
    addrs = sorted(image)
    if not addrs:
        raise SystemExit('no object code found in listing')
    for base in range(addrs[0], addrs[-1] + 1, width):
        chunk = [image[a] for a in range(base, min(base + width, addrs[-1] + 1)) if a in image]
        if not chunk:
            continue                      # skip holes entirely, like OH51 does
        # addresses inside a record must be contiguous; split if a hole falls inside
        run_start = base
        run = []
        for a in range(base, min(base + width, addrs[-1] + 1)):
            if a in image:
                if not run:
                    run_start = a
                run.append(image[a])
            else:
                if run:
                    out.append(_record(run_start, run))
                    run = []
        if run:
            out.append(_record(run_start, run))
    out.append(':00000001FF')
    return '\r\n'.join(out) + '\r\n'


def _record(addr, data):
    if addr > 0xFFFF:
        raise SystemExit('address 0x%04X out of 16-bit range' % addr)
    n = len(data)
    body = [n, (addr >> 8) & 0xFF, addr & 0xFF, 0x00] + list(data)
    checksum = (-sum(body)) & 0xFF
    return ':' + ''.join('%02X' % b for b in body) + '%02X' % checksum


def main(argv):
    if len(argv) < 2:
        raise SystemExit(__doc__.strip().splitlines()[-3].strip())
    lst = argv[1]
    hexout = argv[2] if len(argv) > 2 else re.sub(r'\.LST$', '', lst, flags=re.I) + '_lst.hex'

    image, code_lines, collisions = parse_lst(lst)
    gaps = blank_ranges(image)
    addrs = sorted(image)

    print('lst2hex: %s' % lst)
    print('  object-code lines : %d' % code_lines)
    print('  bytes emitted     : %d' % len(image))
    print('  address range     : %04X .. %04X' % (addrs[0], addrs[-1]))
    if collisions:
        print('  !! CONFLICTING bytes at same address: %d' % collisions)
    if gaps:
        print('  gaps (unprogrammed, left blank):')
        for lo, hi, n in gaps:
            print('    %04X..%04X (%d bytes)' % (lo, hi, n))
    else:
        print('  gaps              : none')

    with open(hexout, 'w', newline='') as fh:
        fh.write(to_intel_hex(image))
    print('  wrote             : %s' % hexout)
    if collisions:
        raise SystemExit(1)


if __name__ == '__main__':
    main(sys.argv)
