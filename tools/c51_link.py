#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""c51_link.py -- 把 Keil C51 生成的可重定位汇编（.SRC）转成一个绝对地址的 A51 模块。

为什么要有这个工具
------------------
评估版 Keil 的链接器（BL51 和 LX51 都实测过）在代码超过 0800H = 2048 字节时
直接报 L250 并且**拒绝产出 .abs**，所以官方那条 C51 -> BL51 -> OH51 的链路
出不了 hex。而这条链路上真正"卡住"的只有**排地址**这一步：

    C51.EXE   编译器  无限额  -> 能生成汇编源码（.SRC）
    A51.EXE   汇编器  无限额  -> 能汇编绝对模块，清单里就是最终机器码
    lst2hex.py 现成工具       -> 能把 A51 清单直接变成 Intel HEX
    BL51/LX51 链接器  2048 上限  <- 唯一的问题，而且它只干"排地址"

本脚本就用最朴素的办法把它补上：把 .SRC 里那 50 多个可重定位段（RSEG）
拼成**一个绝对模块**，后面的 A51 + lst2hex.py 就一路通了。

为什么可行（都是实测结论，不是推测）
------------------------------------
· .SRC 里 **0 条 ACALL、134 条全 LCALL** -> 跨函数调用全是长调用，段序可以任意排
· **275 个 ?Cxxxx 局部标号去重后仍是 275** -> C51 用的是全局唯一编号，
  合并成一个模块不会重定义
· 模块只引用一个外部符号 `?C_STARTUP`（启动代码），由本脚本自己写掉；
  原来那个 `?C?IMUL`（16 位乘法库例程）已在 C 源码里用移位加法消掉
· 静态变量 56 B + 位变量 8 位 -> 放得进内部 RAM

内存布局（想改就改下面那几个常量）
----------------------------------
    0000H   启动：置栈指针 + LJMP main
    000BH   Timer0 中断向量：LJMP timer0_isr
    0010H   全部函数与常量表（按 .SRC 的段序连续摆放）
    0030H   数据段（DS 变量）
    20H.0   位段（DBIT 变量）
    栈：SP 初值 7FH，向上长到 80H~FFH（间接寻址区，本工程没往里放变量）

用法
----
    python tools/c51_link.py firmware/c51/main.src firmware/c51/main_abs.asm

之后：
    D:\\keli\\C51\\BIN\\A51.EXE main_abs.asm
    python tools/lst2hex.py main_abs.LST main.hex
"""

import os
import re
import sys

# ---- 内存布局（改这里即可重新排布）----
CODE_BASE = 0x0010          # 函数与常量表的起始地址
DATA_BASE = 0x0030          # 直接寻址区变量起始地址
BIT_BASE = 0x0000           # 位地址（0 = 内部 RAM 20H.0）
STACK_TOP = 0x7F            # 栈指针初值（再往上就是 80H~FFH 的间接寻址区）

SEG_RE = re.compile(r'^\s*RSEG\s+(\S+)\s*$')
EXTRN_RE = re.compile(r'^\s*EXTRN\b')
NAME_RE = re.compile(r'^\s*NAME\s+(\S+)\s*$')
END_RE = re.compile(r'^\s*END\s*$')
# .SRC 里 C51 自己会把中断向量写成 "CSEG AT 0000BH" + "LJMP <isr>"
# （没有链接器，这条绝对定位指令必须由本脚本接管，否则它会把位置计数器拽回向量地址，
#   导致后面的代码覆盖到前面已排好的段上）
ABS_RE = re.compile(r'^\s*(CSEG|DSEG|BSEG)\s+AT\s+([0-9A-Fa-f]+)H?\s*$')
ORG_RE = re.compile(r'^\s*ORG\s+(\S+)\s*$')
# 生成汇编里值得保留的注释（其余整行注释都是 C 源码的回显，丢掉以免文件翻倍）
KEEP_COMMENT_RE = re.compile(r'^\s*;\s*(SOURCE LINE #|FUNCTION .*\((BEGIN|END)\)|END OF )')
# 会写进输出的段前缀 -> 归类
CODE_PREFIXES = ('?PR?', '?CO?', '?C_INITSEG')
DATA_PREFIXES = ('?DT?', '?ED?')
BIT_PREFIXES = ('?BI?',)


def decode(path):
    raw = open(path, 'rb').read()
    for enc in ('utf-8', 'gbk', 'cp1252'):
        try:
            return raw.decode(enc)
        except UnicodeDecodeError:
            continue
    return raw.decode('utf-8', 'replace')


def split_segments(lines):
    """-> (header_lines, [(segname, [lines]), ...])"""
    header = []
    blocks = []
    cur = None
    for ln in lines:
        m = SEG_RE.match(ln)
        if m:
            cur = (m.group(1), [])
            blocks.append(cur)
            continue
        if cur is None:
            header.append(ln)
        else:
            cur[1].append(ln)
    return header, blocks


def kind_of(segname):
    if segname.startswith(CODE_PREFIXES):
        return 'code'
    if segname.startswith(DATA_PREFIXES):
        return 'data'
    if segname.startswith(BIT_PREFIXES):
        return 'bit'
    return None


def extract_vectors(lines):
    """把块里的 "CSEG AT xxxxH" 标记及其后紧跟的指令抠出来。

    -> (剩下的行, [(地址, [指令行]), ...])
    向量块以空行或注释行结束。
    """
    body, vectors = [], []
    cur = None
    for ln in lines:
        m = ABS_RE.match(ln)
        if m:
            cur = (int(m.group(2), 16), [])
            vectors.append(cur)
            continue
        if cur is not None:
            s = ln.strip()
            if s and not s.startswith(';'):
                cur[1].append(ln.rstrip())
                continue
            cur = None                    # 空行/注释 -> 向量块结束
        body.append(ln)
    return body, vectors


def parse_num(s):
    s = s.strip()
    return int(s[:-1], 16) if s.upper().endswith('H') else int(s, 10)


def fix_org(lines, base):
    """把数据段/位段里的 `ORG n` 翻成**绝对地址**。

    ⚠️ 这是个真踩过的坑：C51 在可重定位段里用 `ORG n` 表示"**段内偏移 n**"
    （函数的局部变量复用叠加槽位时会用到）。而我们的段是**绝对**的 ——
    A51 会把 `ORG 1` 当成**绝对地址 1**，数据段基址却是 30H，于是一头撞在段基址下面：

        *** ERROR #A27 ...: LOCATION COUNTER MAY NOT POINT BELOW SEGMENT BASE

    （诊断版 `-Debug` 一开始编不过就是这个原因：`prt_gear` 里有局部变量。）
    """
    out = []
    for ln in lines:
        m = ORG_RE.match(ln)
        if m:
            out.append('\tORG\t%04XH' % (base + parse_num(m.group(1))))
        else:
            out.append(ln)
    return out


def clean_block(lines):
    """丢掉尾部的 END、空段、以及 C 源码回显注释。"""
    out = []
    for ln in lines:
        if END_RE.match(ln):
            continue
        if EXTRN_RE.match(ln):
            continue
        s = ln.strip()
        if s.startswith(';') and not KEEP_COMMENT_RE.match(ln):
            continue
        if s and not s.startswith(';'):
            out.append(ln.rstrip())
        elif KEEP_COMMENT_RE.match(ln):
            out.append(ln.rstrip())
    return out


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    src_path = argv[1]
    out_path = argv[2] if len(argv) > 2 else os.path.splitext(src_path)[0] + '_abs.asm'

    lines = decode(src_path).splitlines()
    header, blocks = split_segments(lines)

    # ---- 头部：换掉 NAME，丢掉 EXTRN ----
    head = []
    modname = None
    for ln in header:
        if EXTRN_RE.match(ln):
            continue
        m = NAME_RE.match(ln)
        if m:
            modname = m.group(1) + '_ABS'
            head.append('\tNAME\t%s' % modname)
            continue
        if ln.strip():
            head.append(ln.rstrip())

    # ---- 分段归类 ----
    code, data, bit, unknown = [], [], [], []
    vectors = []
    for segname, body in blocks:
        k = kind_of(segname)
        body, vecs = extract_vectors(body)
        vectors.extend(vecs)
        cleaned = clean_block(body)
        if k is None:
            unknown.append((segname, cleaned))
        elif not cleaned:
            continue                        # 空段（例如没有静态初值时的初始化段）
        elif k == 'code':
            code.append((segname, cleaned))
        elif k == 'data':
            data.append((segname, cleaned))
        else:
            bit.append((segname, cleaned))

    if unknown:
        print('!! 出现无法归类的段，先看清楚再改脚本：')
        for name, body in unknown:
            print('   %s  (%d 行)' % (name, len(body)))
        return 1

    # 代码段里若出现 ORG，不能照搬：可重定位段里它表示"段内偏移"，
    # 在绝对段里会被当成绝对地址。宁可不编，也不出错 hex。
    for segname, body in code:
        for ln in body:
            if ORG_RE.match(ln):
                print('!! 代码段 %s 里出现 ORG，本脚本无法直接照搬：' % segname)
                print('   可重定位段里 ORG 表示"段内偏移"，绝对段里会被当成绝对地址。')
                print('   要么像数据段那样按"本段起始地址 + 偏移"改写（要先知道段地址），')
                print('   要么先确认这条 ORG 是否真的必要。')
                return 1

    # ?C_INITSEG 是 C 运行期初始化段，而**本脚本的启动代码不会去执行它**，
    # 所以它一旦非空，就说明 C 源码里出现了**静态初值** —— 那个变量上电会是随机值。
    # 宁可不编，也不出错 hex。
    for segname, body in code:
        if segname.startswith('?C_INITSEG') and body:
            print('!! %s 非空 —— C 源码里有**静态初值**，但本工程的启动代码不跑初始化段：' % segname)
            for ln in body[:6]:
                print('     ' + ln.strip())
            print('   => 把那个变量的初值挪进 init_all()（不要写 static x = ...）。')
            return 1

    ext = [ln.strip() for ln in lines
           if EXTRN_RE.match(ln) and '?C_STARTUP' not in ln]
    if ext:
        print('!! 还有外部符号没解决：')
        for e in ext:
            print('   ' + e)
        print('   （本脚本只替代 ?C_STARTUP。其余外部符号需要在 C 源码里消掉。）')
        return 1

    # ---- 生成绝对模块 ----
    out = []
    out.append(';=========================================================================')
    out.append('; %s  --  **自动生成，请勿手改**' % os.path.basename(out_path))
    out.append(';-------------------------------------------------------------------------')
    out.append(';   来源 : %s' % os.path.basename(src_path))
    out.append(';   生成 : python tools\\c51_link.py %s' % os.path.basename(src_path))
    out.append(';')
    out.append(';   作用 : 把 C51 生成的 %d 个可重定位段拼成**一个绝对地址模块**，' % len(blocks))
    out.append(';          这样 A51（评估版无限额）就能直接汇编出最终机器码，')
    out.append(';          再由 tools\\lst2hex.py 从清单出 hex ——')
    out.append(';          绕开评估版链接器 BL51 / LX51 的 2048 字节上限。')
    out.append(';')
    out.append(';   布局 : 代码 %04XH 起 / 数据 %04XH 起 / 位 %02XH 起 / 栈顶 %02XH' %
               (CODE_BASE, DATA_BASE, BIT_BASE + 0x20, STACK_TOP))
    out.append(';   对应关系 : 每段前面标了原来的段名，段内保留 "; SOURCE LINE # n"')
    out.append(';              可以据此回到 main.c 的对应行。')
    out.append(';=========================================================================')
    out.append('')
    out.extend(head)
    out.append('')
    out.append(';=========================================================================')
    out.append('; 启动代码（替代 Keil 的 ?C_STARTUP）')
    out.append(';   本固件的变量全部在 init_all() 里显式初始化，没有任何静态初值，')
    out.append(';   所以 C 运行期不需要初始化段；这里只做两件事：置栈指针、跳到 main。')
    out.append(';   栈：SP 初值 %02XH，压栈先加后存 -> 实际用到 80H 起，' % STACK_TOP)
    out.append(';       80H~FFH 是间接寻址区（只能 MOV @Ri 访问），本工程没往那儿放变量。')
    out.append(';=========================================================================')
    out.append('')
    out.append('\tCSEG\tAT\t%04XH' % 0)
    out.append('\t\tMOV\tSP, #%02XH' % STACK_TOP)
    out.append('\t\tLJMP\tmain')
    out.append('')

    # ---- 中断向量：C51 已经在 .SRC 里写好了，原样搬过来 ----
    out.append(';=========================================================================')
    out.append('; 中断向量表')
    out.append(';   这几条是 C51 在 .SRC 里自己生成的（不是本脚本编的），')
    out.append(';   原来由链接器摆放；这里原样接管，所以以后 C 源码里加新的中断函数，')
    out.append(';   向量会自动跟着出来，不用改这个脚本。')
    out.append(';   复位向量在上面（由本脚本的启动代码接管，替代 ?C_STARTUP）。')
    out.append(';=========================================================================')
    seen_addr = {}
    for addr, vlines in vectors:
        if addr in seen_addr:
            print('!! 中断向量地址 %04XH 出现了两次' % addr)
            return 1
        seen_addr[addr] = vlines
        out.append('')
        out.append('\tCSEG\tAT\t%04XH' % addr)
        out.extend(vlines)
    if not vectors:
        out.append('')
        out.append(';   （这个模块没有中断向量）')
    out.append('')
    out.append(';=========================================================================')
    out.append('; 代码：全部函数 + 常量表，按 .SRC 的段序连续摆放')
    out.append(';   段序可以任意 —— 实测 .SRC 里 0 条 ACALL、134 条全 LCALL，')
    out.append(';   跨函数调用都是长调用，不受 2 KB 页限制。')
    out.append(';=========================================================================')
    out.append('')
    out.append('\tCSEG\tAT\t%04XH' % CODE_BASE)
    for segname, body in code:
        out.append('')
        out.append(';--------------------------------------------------------------- %s' % segname)
        out.extend(body)

    out.append('')
    out.append(';=========================================================================')
    out.append('; 数据段：直接寻址区（原 ?DT? 段）')
    out.append(';   放进 %02XH 起，剩下的留给栈。' % DATA_BASE)
    out.append(';   ⚠️ 段内的 ORG 已由本脚本翻成绝对地址（C51 在可重定位段里')
    out.append(';      用 ORG 表示"段内偏移"，照搬进绝对段会撞到段基址以下）。')
    out.append(';=========================================================================')
    out.append('')
    out.append('\tDSEG\tAT\t%04XH' % DATA_BASE)
    for segname, body in data:
        out.append('')
        out.append(';--------------------------------------------------------------- %s' % segname)
        out.extend(fix_org(body, DATA_BASE))

    out.append('')
    out.append(';=========================================================================')
    out.append('; 位段：位寻址区（原 ?BI? 段）')
    out.append(';   位地址 0 就是内部 RAM 20H.0，位寻址范围 00H~7FH = 20H~2FH。')
    out.append(';=========================================================================')
    out.append('')
    out.append('\tBSEG\tAT\t%04XH' % BIT_BASE)
    for segname, body in bit:
        out.append('')
        out.append(';--------------------------------------------------------------- %s' % segname)
        out.extend(fix_org(body, BIT_BASE))

    out.append('')
    out.append('\tEND')
    out.append('')

    with open(out_path, 'w', encoding='utf-8', newline='\r\n') as fh:
        fh.write('\n'.join(out))

    # ---- 报告 ----
    print('c51_link: %s -> %s' % (src_path, out_path))
    print('  模块名        : %s' % (modname or '(未找到 NAME)'))
    print('  .SRC 段总数   : %d' % len(blocks))
    print('  代码段        : %d  (函数 + 常量表 + 初始化段)' % len(code))
    print('  数据段        : %d  -> DSEG AT %04XH' % (len(data), DATA_BASE))
    print('  位段          : %d  -> BSEG AT %04XH' % (len(bit), BIT_BASE))
    print('  中断向量      : %d 个  %s' %
          (len(vectors), ', '.join('%04XH' % a for a, _ in vectors) or '(无)'))
    print('  跳过的空段    : %d' % (len(blocks) - len(code) - len(data) - len(bit)))
    print('  未解决的外部符号: 无')
    print()
    print('  下一步：')
    print('    D:\\keli\\C51\\BIN\\A51.EXE %s' % os.path.basename(out_path))
    print('    python tools\\lst2hex.py %s %s' %
          (os.path.splitext(os.path.basename(out_path))[0] + '.LST',
           os.path.splitext(os.path.basename(out_path))[0] + '.hex'))
    return 0


if __name__ == '__main__':
    raise SystemExit(main(sys.argv))
