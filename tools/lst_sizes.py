# -*- coding: utf-8 -*-
"""从 Keil A51 生成的 .LST 清单里，按标号拆出每个子程序/数据块的实测字节数。

用法:
    python lst_sizes.py <file.LST> [--top N] [--all]

输出:
    1) 指令字节 / DB-DW 数据字节 的分账
    2) 各标号区间的字节数（= 该子程序的实际体积），按体积降序
    3) 合计，用于和链接器报告的 code= 对比

为什么要有这个工具:
    Keil 只报"整个程序 1147 字节"，不报"红外解码占多少、串口打印占多少"。
    排 2KB 预算必须知道每一块的价码，否则只能拍脑袋。

A51 .LST 行格式（实测）:
    00CB F540            233                 MOV     LASTCMD, A
    ^LOC ^obj(hex pairs)  ^行号  ^源文本
    LOC 列与行号列之间可能有大段空格；源文本很长的行会被折到下一行（LOC 与行号列留空）。
"""
import re
import sys

# LOC(4 hex) + 空格 + 目标码(只含 hex 与空格) + 2 个以上空格 + 行号 + 空格 + 源文本
WITH_LOC = re.compile(r'^([0-9A-F]{4}) ([0-9A-F ]*?)\s{2,}(\d+) (.*)$')
# LOC + 目标码，没有行号/源文本 —— 源文本过长的行，目标码会溢出到这种续行上
CONT_LOC = re.compile(r'^([0-9A-F]{4}) ([0-9A-F ]*?)\s*$')
# 续行：LOC 与行号列留空
NO_LOC = re.compile(r'^\s{2,}(\d+) (.*)$')
LABEL = re.compile(r'^\s*([A-Za-z_?$][\w?$]*)\s*:')
DATADIR = re.compile(r'^\s*(DB|DBIT|DW)\b', re.I)


def decode(path):
    raw = open(path, 'rb').read()
    for enc in ('utf-8', 'gbk', 'cp1252'):
        try:
            return raw.decode(enc)
        except UnicodeDecodeError:
            continue
    return raw.decode('utf-8', 'replace')


def parse(path):
    """-> list of (loc|None, nbytes, lineno|None, source)"""
    rows = []
    for ln in decode(path).splitlines():
        m = WITH_LOC.match(ln)
        if m:
            obj = m.group(2).replace(' ', '')
            rows.append((int(m.group(1), 16), len(obj) // 2, int(m.group(3)), m.group(4)))
            continue
        m = CONT_LOC.match(ln)
        if m:
            obj = m.group(2).replace(' ', '')
            if not obj:
                continue
            # 溢出到续行的目标码：归属到上一条有源码的行（决定它算指令还是数据）
            src = rows[-1][3] if rows else ''
            rows.append((int(m.group(1), 16), len(obj) // 2, None, src))
            continue
        m = NO_LOC.match(ln)
        if m:
            rows.append((None, 0, int(m.group(1)), m.group(2)))
    return rows


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    top = None
    if '--top' in sys.argv:
        top = int(sys.argv[sys.argv.index('--top') + 1])
    show_all = '--all' in sys.argv

    rows = parse(sys.argv[1])
    if not rows:
        print('no parsable LST rows')
        return 1

    instr_bytes = sum(n for _l, n, _ln, s in rows if not DATADIR.match(s))
    data_bytes = sum(n for _l, n, _ln, s in rows if DATADIR.match(s))

    marks = [(loc, LABEL.match(s).group(1)) for loc, _n, _ln, s in rows
             if loc is not None and LABEL.match(s)]

    blocks = []
    for i, (loc, name) in enumerate(marks):
        nxt = next((marks[j][0] for j in range(i + 1, len(marks)) if marks[j][0] > loc), None)
        if nxt is not None and nxt > loc:
            blocks.append((nxt - loc, name, loc))

    print('=== %s ===' % sys.argv[1])
    print('指令字节 : %6d' % instr_bytes)
    print('数据字节 : %6d   (DB/DW 常量、字符串、表格)' % data_bytes)
    print('合计     : %6d   <- 应与链接器的 code= 一致' % (instr_bytes + data_bytes))
    print('标号覆盖 : %6d   (%d 个标号)' % (sum(b[0] for b in blocks), len(blocks)))
    print()

    blocks.sort(reverse=True)
    shown = blocks if (show_all or top is None) else blocks[:top]
    print('--- 标号区间体积（字节），降序 %d/%d ---' % (len(shown), len(blocks)))
    for size, name, loc in shown:
        print('  %5d  %-26s @0x%04X' % (size, name, loc))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
