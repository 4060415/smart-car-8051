#!/usr/bin/env python3
"""
compare_hex.py -- compare two Intel HEX files byte for byte.

Used to validate tools/lst2hex.py against the Keil toolchain's own output:
for any firmware small enough for Eval BL51 to link, the image produced by
lst2hex.py must be IDENTICAL to the image BL51+OH51 produced. Only then is it
safe to use lst2hex.py for builds that BL51 refuses (>2048 bytes).

Usage:
    python compare_hex.py a.hex b.hex

Exit code 0 = identical images, 1 = different, 2 = bad input.
"""
import sys


def read_hex(path):
    image = {}
    base = 0
    with open(path, 'r', errors='replace') as fh:
        for lineno, line in enumerate(fh, 1):
            line = line.strip()
            if not line:
                continue
            if not line.startswith(':'):
                raise SystemExit('%s:%d not an Intel HEX record: %r' % (path, lineno, line[:40]))
            raw = bytes.fromhex(line[1:])
            if (sum(raw) & 0xFF) != 0:
                raise SystemExit('%s:%d bad checksum' % (path, lineno))
            count, addr, rtype = raw[0], (raw[1] << 8) | raw[2], raw[3]
            data = raw[4:4 + count]
            if rtype == 0x00:
                for i, b in enumerate(data):
                    image[base + addr + i] = b
            elif rtype == 0x01:
                break
            elif rtype == 0x02:
                base = ((data[0] << 8) | data[1]) << 4
            elif rtype == 0x04:
                base = ((data[0] << 8) | data[1]) << 16
            # ignore other record types
    return image


def main(argv):
    if len(argv) < 3:
        raise SystemExit('usage: compare_hex.py a.hex b.hex')
    a = read_hex(argv[1])
    b = read_hex(argv[2])

    ka, kb = set(a), set(b)
    only_a = sorted(ka - kb)
    only_b = sorted(kb - ka)
    diff = sorted(k for k in ka & kb if a[k] != b[k])

    print('A = %s : %d bytes, range %04X..%04X'
          % (argv[1], len(a), min(ka), max(ka)) if ka else 'A empty')
    print('B = %s : %d bytes, range %04X..%04X'
          % (argv[2], len(b), min(kb), max(kb)) if kb else 'B empty')

    if only_a:
        print('  only in A: %d bytes, first 16 at %s'
              % (len(only_a), ' '.join('%04X' % x for x in only_a[:16])))
    if only_b:
        print('  only in B: %d bytes, first 16 at %s'
              % (len(only_b), ' '.join('%04X' % x for x in only_b[:16])))
    if diff:
        print('  DIFFERING bytes: %d' % len(diff))
        for k in diff[:24]:
            print('    %04X: A=%02X B=%02X' % (k, a[k], b[k]))

    if not only_a and not only_b and not diff:
        print('IDENTICAL: the two images are byte-for-byte equal.')
        return 0
    print('MISMATCH.')
    return 1


if __name__ == '__main__':
    sys.exit(main(sys.argv))
