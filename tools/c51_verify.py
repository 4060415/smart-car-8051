#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""c51_verify.py -- 核对"手工排地址"这一步没有改动编译器的产物。

为什么需要它
------------
走 tools/c51_link.py 这条路时 Keil 链接器被**绕过了**，所以拿不到官方的参考 hex
（评估版链接器一遇到超 2048 字节就报 L250 并拒绝产出 .abs，没有可比对的基准）。
于是退而求其次，拿两份清单**逐函数**对：

    main.lst      C51 编译产物清单        —— 每个函数占多少字节
    main_abs.LST  A51 汇编后的绝对模块清单 —— 每个函数占多少字节

只要**每个函数的字节数完全一致**，就说明"自己排地址"只是把代码搬了个地方，
没有多一个字节、也没有少一个字节。

（同族的回归测试：lst2hex.py 的文档里写明，凡是 BL51 能链接的构建，
都要用 compare_hex.py 逐字节比对；而超限的 C 版没有这个基准，
本脚本就是它的替代品。）

用法：
    python tools/c51_verify.py firmware/c51/main.lst firmware/c51/main_abs.LST

保持本文件纯 ASCII（Windows 控制台是 GBK）。
"""
import re
import sys

C51_LINE = re.compile(r'^([0-9A-F]{4}) ((?:[0-9A-F]{2} ?)+)')
C51_FUNC = re.compile(r';\s*FUNCTION\s+(\S+)\s+\((BEGIN|END)\)')

A51_LINE = re.compile(r'^([0-9A-F]{4}) ([0-9A-F]*)(?:\s+(\d+))?\s*(.*)$')
A51_LABEL = re.compile(r'^([A-Za-z_?$][\w?$]*)\s*:')


def decode(path):
    raw = open(path, 'rb').read()
    for enc in ('utf-8', 'gbk', 'cp1252'):
        try:
            return raw.decode(enc)
        except UnicodeDecodeError:
            continue
    return raw.decode('utf-8', 'replace')


def parse_c51(path):
    """-> (per-function bytes, bytes before the first function, total)

    归属规则（很重要）：C51 会把"共享尾代码"另列成一个 `L?xxxx` 块，而且**没有 END 标记**；
    在 A51 那边排完地址后，这些字节自然算在**前一个函数**名下。
    所以这里只在遇到**真正的函数** BEGIN 时切换归属，`L?xxxx` 块和所有 END 标记都忽略。
    这样两边的口径才一致，比对才有意义。
    """
    text = decode(path)
    inside = False
    cur = None
    sizes = {}
    loose = 0
    total = 0
    for ln in text.splitlines():
        if 'ASSEMBLY LISTING OF GENERATED OBJECT CODE' in ln:
            inside = True
            continue
        if not inside:
            continue
        if ln.startswith('NAME ') or ln.startswith('SYMBOL TABLE'):
            break
        m = C51_FUNC.search(ln)
        if m:
            name, kind = m.group(1), m.group(2)
            if kind == 'BEGIN' and not name.startswith('L?'):
                if cur is not None:
                    sizes[cur[0]] = sizes.get(cur[0], 0) + cur[1]
                cur = [name, 0]
            continue
        m = C51_LINE.match(ln)
        if m:
            n = len(m.group(2).replace(' ', '')) // 2
            total += n
            if cur is None:
                loose += n
            else:
                cur[1] += n
    if cur is not None:
        sizes[cur[0]] = sizes.get(cur[0], 0) + cur[1]
    return sizes, loose, total


def parse_a51(path, known):
    """-> (per-function bytes, bytes outside any known function)"""
    text = decode(path)
    sizes = {}
    cur = None
    outside = 0
    for ln in text.splitlines():
        if ln.startswith('SYMBOL TABLE') or 'SYMBOL TABLE LISTING' in ln:
            break
        m = A51_LINE.match(ln)
        if not m:
            continue
        obj = m.group(2)
        src = m.group(4) or ''
        lm = A51_LABEL.match(src.strip())
        if lm and lm.group(1) in known:
            cur = lm.group(1)
            continue
        if not obj or len(obj) % 2:
            continue
        n = len(obj) // 2
        if cur is None:
            outside += n
        else:
            sizes[cur] = sizes.get(cur, 0) + n
    return sizes, outside


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2

    c51, c51_loose, c51_total = parse_c51(argv[1])
    a51, a51_outside = parse_a51(argv[2], set(c51))

    print('=== 逐函数目标码字节数比对 ===')
    print('  C51 清单 : %s' % argv[1])
    print('     函数 %d 个, 合计 %d 字节;  函数之外 %d 字节' %
          (len(c51), sum(c51.values()), c51_loose))
    print('  A51 清单 : %s' % argv[2])
    print('     函数 %d 个, 合计 %d 字节;  函数之外 %d 字节' %
          (len(a51), sum(a51.values()), a51_outside))
    print('      （A51 的函数之外 = 启动代码 + 中断向量 + 常量表，'
          'C51 清单里不含这些）')
    print('  C51 全部目标码 %d + 启动/向量/常量 %d = %d，'
          'A51 全部目标码 %d' % (c51_total, a51_outside - c51_loose,
                                c51_total + a51_outside - c51_loose,
                                sum(a51.values()) + a51_outside))
    print()

    bad = 0
    missing = [k for k in c51 if k not in a51]
    extra = [k for k in a51 if k not in c51]
    for name in sorted(c51, key=lambda n: -c51[n]):
        a = a51.get(name)
        if a is None:
            print('  %-24s C51 %4d  A51  ——   函数在 A51 清单里找不到' % (name, c51[name]))
            bad += 1
            continue
        if a != c51[name]:
            print('  %-24s C51 %4d  A51 %4d   差 %+d' % (name, c51[name], a, a - c51[name]))
            bad += 1
    if extra:
        for name in extra:
            print('  %-24s C51  ——   A51 %4d   多出来的函数' % (name, a51[name]))
        bad += 1

    print()
    if bad:
        print('结果: 不一致 %d 处 —— 排地址这一步改动了产物，必须查清' % bad)
        return 1
    print('结果: 全部 %d 个函数字节数一致 -- 排地址只搬动、没改动  OK' % len(c51))
    return 0


if __name__ == '__main__':
    raise SystemExit(main(sys.argv))
