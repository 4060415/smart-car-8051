# -*- coding: utf-8 -*-
"""从 Keil C51 生成的 .LST 清单里，按函数拆出实测目标码字节数。

用法:
    python c51_sizes.py <file.LST> [--top N] [--all]

前提:
    编译时要带 CODE 指令，否则 .LST 里没有汇编清单：
        C51.EXE main.c SMALL DEBUG CODE

为什么要有这个工具:
    链接器（BL51/LX51）在评估版下超过 0800H 字节就直接 L250 报错、**不产出 .abs**，
    所以拿不到 "Program Size: code=xxxx" 这一行。
    但编译器本身没有限额，它生成的汇编清单里每一条指令都带着目标码字节，
    把它们加起来就是 code 体积 —— 这就是评估版下唯一能用的体积口径。

C51 清单行格式（实测）:
    0004 75D008            MOV     PSW,#08H
    ^LOC ^目标码(hex 对)   ^生成的汇编
    只有标号的行没有目标码（例：0010         ?C0001:）
    函数边界用注释标出：  ; FUNCTION timer0_isr (BEGIN) ... (END)
"""
import re
import sys

LINE = re.compile(r'^([0-9A-F]{4}) ((?:[0-9A-F]{2} ?)+)')
FUNC = re.compile(r';\s*FUNCTION\s+(\S+)\s+\((BEGIN|END)\)')


def decode(path):
    raw = open(path, 'rb').read()
    for enc in ('utf-8', 'gbk', 'cp1252'):
        try:
            return raw.decode(enc)
        except UnicodeDecodeError:
            continue
    return raw.decode('utf-8', 'replace')


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    top = None
    if '--top' in sys.argv:
        top = int(sys.argv[sys.argv.index('--top') + 1])

    text = decode(sys.argv[1])
    if 'ASSEMBLY LISTING OF GENERATED OBJECT CODE' not in text:
        print('这个 .LST 里没有生成汇编清单 —— 编译时要加 CODE 指令：')
        print('    C51.EXE <name>.c SMALL DEBUG CODE')
        return 1

    inside = False
    cur = None
    funcs = []            # (name, bytes, first_loc)
    loose = 0             # 函数之外的目标码（常量段、跳转表等）
    total = 0
    hi = 0

    for ln in text.splitlines():
        if 'ASSEMBLY LISTING OF GENERATED OBJECT CODE' in ln:
            inside = True
            continue
        if not inside:
            continue
        if ln.startswith('NAME ') or ln.startswith('SYMBOL TABLE'):
            break

        m = FUNC.search(ln)
        if m:
            if m.group(2) == 'BEGIN':
                cur = [m.group(1), 0, None]
            else:
                if cur:
                    funcs.append(tuple(cur))
                cur = None
            continue

        m = LINE.match(ln)
        if not m:
            continue
        n = len(m.group(2).replace(' ', '')) // 2
        loc = int(m.group(1), 16)
        total += n
        if loc + n > hi:
            hi = loc + n
        if cur is not None:
            if cur[2] is None:
                cur[2] = loc
            cur[1] += n
        else:
            loose += n

    print('=== %s ===' % sys.argv[1])
    print('本模块 code 合计 : %6d 字节   (最高地址 0x%04X)' % (total, hi))
    print('  其中函数体内   : %6d' % (total - loose))
    print('  其中函数体外   : %6d   (常量表 / 字符串 / 跳转表)' % loose)
    print('  函数个数       : %6d' % len(funcs))
    print()
    print('  参考：评估版链接器上限 = 2048 字节（0800H）；'
          '本工程汇编版定版 = 2740 字节')
    print()

    funcs.sort(key=lambda f: -f[1])
    shown = funcs if top is None else funcs[:top]
    print('--- 函数体积（字节），降序 %d/%d ---' % (len(shown), len(funcs)))
    for name, size, loc in shown:
        print('  %5d  %-22s @0x%04X' % (size, name, loc or 0))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
