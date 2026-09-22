#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
c51_isr_time.py -- 量 timer0_isr 的最坏路径占多少个机器周期（只读清单，不改任何东西）

为什么需要它
------------
本工程的中断每 99.83us（T0 方式2，重装值 164）跑一次，也就是**只有 92 个机器周期**
的预算（11.0592MHz / 12 = 921.6kHz -> 1 机器周期 = 1.085us；99.83/1.085 = 92）。

C 编译出来的中断比手写汇编长得多（汇编版约 60 个周期）。一旦超过 92：
  - 中断还没退出来，下一次 T0 溢出就到了；方式2 只有一个溢出标志，
    中间那次**会被吞掉** -> 时基开始**走慢**（PWM 频率、10ms 节拍、"1 秒"全都偏）。
  - 这种故障非常隐蔽：车还能跑、灯还会亮，只是所有时间都"变长了"。

怎么算（两条都给，第二条才是答案）
----------------------------------
  ① 静态求和：函数里每条指令的周期全加起来。
     **这不是答案**：中断里有条件分支（PWM 重置、蜂鸣器、超声…），
     实际一趟只走其中一条，求和偏大很多。它的用处是"如果连求和都过关，那就绝对安全"。

  ② 最坏路径：按 A51 清单先把**控制流图**建出来（无条件跳转 / 条件跳转 / 落空 / 返回），
     在图上求**从入口到出口的最长路径**。这才是真上界。
     - 有回头跳转（循环）时图不是 DAG，会明确警告并退化成"用求和当上界"。
     - 有 LCALL/ACALL 时会去找被调函数的地址并递归算它的最坏路径（找不到就按保守值计）。

判据
----
  最坏路径 + 4（中断向量 LJMP + 末尾 RETI）< 92  ->  安全
  >= 92                                          ->  必然丢时基，必须精简中断

用法
    python tools/c51_isr_time.py firmware/c51/main_abs.LST [函数名]
"""

import io
import re
import sys

# ---- 8051 指令周期表（12 分频，单位 = 机器周期）----
ONE = {'NOP', 'RR', 'RL', 'RRC', 'RLC', 'SWAP', 'DA'}
TWO = {
    'AJMP', 'LJMP', 'SJMP', 'ACALL', 'LCALL', 'RET', 'RETI',
    'JZ', 'JNZ', 'JC', 'JNC', 'JB', 'JNB', 'JBC', 'CJNE', 'DJNZ',
    'PUSH', 'POP', 'MOVX', 'XCH', 'XCHD', 'MOVC',
}
COND = {'JZ', 'JNZ', 'JC', 'JNC', 'JB', 'JNB', 'JBC', 'CJNE', 'DJNZ'}
UNCOND = {'SJMP', 'AJMP', 'LJMP'}
CALLS = {'LCALL', 'ACALL'}
EXIT = {'RET', 'RETI'}

INST_RE = re.compile(r'^([0-9A-F]{4})\s+([0-9A-F]{2}(?: ?[0-9A-F]{2})*)\s+(\d+)\s+(\S.*)$')
LABEL_RE = re.compile(r'^([0-9A-F]{4})\s+(\d+)\s+(\S.*)$')


def split_ops(ops):
    out, cur = [], ''
    for ch in ops:
        if ch == ',':
            out.append(cur.strip().upper())
            cur = ''
            continue
        cur += ch
    if cur.strip():
        out.append(cur.strip().upper())
    return out


def is_rn(op):
    return bool(re.fullmatch(r'R[0-7]', op))


def is_atri(op):
    return bool(re.fullmatch(r'@R[01]', op)) or op in ('@A+DPTR', '@A+PC')


def is_direct(op):
    if not op or op.startswith('#') or op.startswith('@'):
        return False
    if op in ('A', 'C', 'AB', 'DPTR'):
        return False
    return not is_rn(op)


def cycles(mnem, ops):
    """返回 (机器周期, 说明)；None 表示不认识。"""
    m = mnem.upper()
    parts = split_ops(ops)
    if m == 'MOV':
        u = ops.upper()
        if 'DPTR' in u:
            return 2, 'MOV DPTR,#imm16'
        if len(parts) == 2:
            d, s = parts
            if d == 'C':
                return 1, ''
            if s == 'C':
                return 2, 'MOV bit,C'
            if is_direct(d) and is_direct(s):
                return 2, 'MOV direct,direct'
            if is_direct(d) and s.startswith('#'):
                return 2, 'MOV direct,#imm'
            if is_atri(d) or is_atri(s):
                return (2, 'MOV @Ri<->direct') if (is_direct(d) or is_direct(s)) else (1, '')
            if is_direct(s) and not (d == 'A' or is_rn(d)):
                return 2, 'MOV Rn,direct'
        return 1, ''
    if m in ('INC', 'DEC'):
        return (2, 'INC/DEC DPTR') if 'DPTR' in ops.upper() else (1, '')
    if m in ('ANL', 'ORL', 'XRL'):
        if len(parts) == 2:
            d, s = parts
            if d == 'C':
                return 2, 'ANL/ORL C,bit'
            if is_direct(d) and s.startswith('#'):
                return 2, 'ANL/ORL/XRL direct,#imm'
        return 1, ''
    if m in ('ADD', 'ADDC', 'SUBB'):
        return 1, ''
    if m in ('MUL', 'DIV'):
        return 4, ''
    if m in ('CLR', 'CPL', 'SETB'):
        # CLR/CPL/SETB bit = 1；CLR A / CPL A 也是 1
        return 1, ''
    if m in ONE:
        return 1, ''
    if m in TWO:
        return 2, ''
    return None, 'UNKNOWN'


def parse_function(lines, start):
    """从 start（函数标签那一行）开始，收集到下一个非 '?' 开头的标签为止。"""
    out = []
    srcline = 0
    for ln in lines[start + 1:]:
        ml = LABEL_RE.match(ln)
        if ml and ml.group(3).strip().endswith(':'):
            lab = ml.group(3).strip().rstrip(':')
            if not lab.startswith('?'):
                break
        ms = re.search(r';\s*SOURCE LINE #\s*(\d+)', ln)
        if ms:
            srcline = int(ms.group(1))
            continue
        mi = INST_RE.match(ln)
        if not mi:
            continue
        src = mi.group(4).strip()
        if src.startswith(';'):
            continue
        toks = src.split(None, 1)
        mnem = toks[0]
        if mnem.upper() in ('DB', 'DW', 'DS', 'EQU', 'DATA', 'BIT', 'SEGMENT',
                            'ORG', 'END', 'USING', 'PUBLIC', 'EXTRN'):
            continue
        nbytes = len(mi.group(2).replace(' ', '')) // 2
        ops = toks[1] if len(toks) > 1 else ''
        c, note = cycles(mnem, ops)
        out.append({
            'addr': int(mi.group(1), 16),
            'len': nbytes,
            'mnem': mnem.upper(),
            'ops': ops,
            'cyc': c,
            'src': src,
            'line': srcline,
        })
    return out


def build_labels(lines):
    labels = {}
    for ln in lines:
        ml = LABEL_RE.match(ln)
        if ml and ml.group(3).strip().endswith(':'):
            labels[ml.group(3).strip().rstrip(':')] = int(ml.group(1), 16)
    return labels


def resolve_target(ops, labels):
    for p in reversed([x.strip() for x in ops.split(',')]):
        if re.fullmatch(r'[0-9A-F]+[Hh]', p):
            return int(p[:-1], 16)
        if p in labels:
            return labels[p]
    return None


def analyze(instrs, labels, lines, depth=0, seen=None):
    """返回 (worst_cycles, notes, has_loop, unknown_count)。"""
    if seen is None:
        seen = set()
    notes = []
    unknown = 0
    if not instrs:
        return 0, notes, False, unknown

    by_addr = {ins['addr']: ins for ins in instrs}
    addrs = sorted(by_addr)
    top = addrs[-1]

    # 未知助记符：按 2 个周期保守计
    for ins in instrs:
        if ins['cyc'] is None:
            unknown += 1
            ins['cyc'] = 2

    memo = {}
    has_loop = [False]
    # 记录最长路径上每个地址选了哪个后继，用来把路径还原出来
    choice = {}

    def longest(addr, stack):
        if addr in memo:
            return memo[addr]
        ins = by_addr.get(addr)
        if ins is None:
            return 0                                  # 走出函数体（不该发生）
        if addr in stack:
            has_loop[0] = True
            return 0
        stack.add(addr)
        nxt = addr + ins['len']
        m = ins['mnem']
        if m in EXIT:
            val = ins['cyc']
            choice[addr] = None
        elif m in UNCOND:
            tgt = resolve_target(ins['ops'], labels)
            val = ins['cyc'] + (longest(tgt, stack) if tgt is not None else 0)
            choice[addr] = tgt
        elif m in COND:
            tgt = resolve_target(ins['ops'], labels)
            a = longest(tgt, stack) if tgt is not None else 0
            b = longest(nxt, stack) if nxt <= top + 3 else 0
            if a >= b:
                val = ins['cyc'] + a
                choice[addr] = tgt
            else:
                val = ins['cyc'] + b
                choice[addr] = nxt
        elif m in CALLS:
            tgt = resolve_target(ins['ops'], labels)
            callee = 0
            if tgt is not None:
                # 找到该地址对应的函数标签，递归算它
                name = None
                for lab, a2 in labels.items():
                    if a2 == tgt and not lab.startswith('?'):
                        name = lab
                        break
                if name and name not in seen and depth < 4:
                    seen.add(name)
                    idx = find_label_line(lines, name)
                    if idx is not None:
                        sub = parse_function(lines, idx)
                        callee, n2, lp2, u2 = analyze(sub, labels, lines, depth + 1, seen)
                        notes.extend(n2)
                        if lp2:
                            has_loop[0] = True
                        unknown += u2
                    else:
                        callee = 100
                else:
                    # 库函数（?C?xxx）或递归过深：按保守值计
                    callee = 100
                    notes.append('conservative 100 cycles for call at %04X -> %s'
                                 % (addr, ins['ops']))
            val = ins['cyc'] + callee + (longest(nxt, stack) if nxt <= top + 3 else 0)
            choice[addr] = nxt if nxt <= top + 3 else None
        else:
            val = ins['cyc'] + (longest(nxt, stack) if nxt <= top + 3 else 0)
            choice[addr] = nxt if nxt <= top + 3 else None
        stack.discard(addr)
        memo[addr] = val
        return val

    w = longest(addrs[0], set())

    # ---- 再算一遍"最短路径"= 所有条件分支都走最省的那一支，当"典型一趟"看待 ----
    memo2 = {}

    def shortest(addr, stack):
        if addr in memo2:
            return memo2[addr]
        ins = by_addr.get(addr)
        if ins is None:
            return 0
        if addr in stack:
            return 0
        stack.add(addr)
        nxt = addr + ins['len']
        m = ins['mnem']
        if m in EXIT:
            val = ins['cyc']
        elif m in UNCOND:
            tgt = resolve_target(ins['ops'], labels)
            val = ins['cyc'] + (shortest(tgt, stack) if tgt is not None else 0)
        elif m in COND:
            tgt = resolve_target(ins['ops'], labels)
            a = shortest(tgt, stack) if tgt is not None else 0
            b = shortest(nxt, stack) if nxt <= top + 3 else 0
            val = ins['cyc'] + min(a, b)
        elif m in CALLS:
            val = ins['cyc'] + shortest(nxt, stack) if nxt <= top + 3 else ins['cyc']
        else:
            val = ins['cyc'] + (shortest(nxt, stack) if nxt <= top + 3 else 0)
        stack.discard(addr)
        memo2[addr] = val
        return val

    s = shortest(addrs[0], set())
    return w, s, notes, has_loop[0], unknown, choice, addrs[0]


def find_label_line(lines, name):
    for i, ln in enumerate(lines):
        ml = LABEL_RE.match(ln)
        if ml and ml.group(3).strip().rstrip(':') == name and ml.group(3).strip().endswith(':'):
            return i
    return None


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    path = sys.argv[1]
    want = sys.argv[2] if len(sys.argv) > 2 else 'timer0_isr'

    lines = io.open(path, encoding='utf-8', errors='replace').read().splitlines()
    labels = build_labels(lines)
    idx = find_label_line(lines, want)
    if idx is None:
        print('FAIL: label %s: not found in %s' % (want, path))
        return 1

    instrs = parse_function(lines, idx)
    naive = sum(ins['cyc'] for ins in instrs)
    worst, best, notes, has_loop, unknown, choice, entry = analyze(instrs, labels, lines)

    # ---- 把最长路径还原出来，按 C 源码行汇总，看周期花在哪 ----
    by_addr = {ins['addr']: ins for ins in instrs}
    trace = []
    a = entry
    guard = 0
    while a is not None and a in by_addr and guard < 500:
        ins = by_addr[a]
        trace.append(ins)
        a = choice.get(a)
        guard += 1
    per_line = {}
    order = []
    for ins in trace:
        k = ins['line']
        if k not in per_line:
            per_line[k] = 0
            order.append(k)
        per_line[k] += ins['cyc']

    overhead = 4                                   # 000BH 的 LJMP(2) + 末尾 RETI(2)
    tick = 92                                      # 一个 tick = 92 个机器周期（TH0=164）
    hard = 2 * tick                                # 2 个 tick：一个中断里挤进 2 次溢出才会真丢计数
    W = worst + overhead
    B = best + overhead
    print('=== %s timing (machine cycles; 1 cyc = 1.085us) ===' % want)
    print('  instructions           : %d' % len(instrs))
    print('  (a) naive sum of all   : %d  (%.1f us)  <-- NOT the answer, just an upper bound'
          % (naive, naive * 1.085))
    print('  (b) longest CFG path   : %d  +%d = %d  (%.1f us)  <-- worst case'
          % (worst, overhead, W, W * 1.085))
    print('  (c) shortest CFG path  : %d  +%d = %d  (%.1f us)  <-- typical tick'
          % (best, overhead, B, B * 1.085))
    print()
    print('  one tick        = %d cycles (99.83 us)' % tick)
    print('  HARD limit      = %d cycles (2 ticks): a single ISR spanning 2 overflows'
          % hard)
    print('                    makes TF0 merge -> the tick counter really loses time.')
    print('  worst / hard    = %d / %d  -> %s' % (W, hard, 'OK, no tick is lost'
          if W < hard else 'OVER -> TICKS ARE LOST'))
    print('  SOFT limit      = %d cycles (1 tick): above this, that tick leaves the'
          % tick)
    print('                    main loop no CPU at all (bursty, but not time loss).')
    print('  typical load    = %d/%d = %d%% of the CPU'
          % (B, tick, round(100.0 * B / tick)))
    print('  worst  load     = %d/%d = %d%% of the CPU'
          % (W, tick, round(100.0 * W / tick)))
    if has_loop:
        print('  NOTE: loop / recursion detected -> (b) is NOT a strict bound;'
              ' fall back to (a) as the bound.')
    if unknown:
        print('  NOTE: %d unrecognised mnemonic(s) counted as 2 cycles each.' % unknown)
    for n in notes:
        print('  NOTE: %s' % n)
    print()
    if '-v' in sys.argv:
        print('--- longest path, by C source line (main.c) ---')
        for k in order:
            print('  line %-5d : %3d cycles' % (k, per_line[k]))
        print('  %-11s : %3d' % ('TOTAL', sum(per_line.values())))
        print()
        print('--- longest path, instruction by instruction ---')
        for ins in trace:
            print('  %04X %-7s %-22s %d  [main.c:%d]'
                  % (ins['addr'], ins['mnem'], ins['ops'][:22], ins['cyc'], ins['line']))
        print()

    if W >= hard:
        print('RESULT: DANGER -- worst case spans 2+ tick periods; the timebase WILL'
              ' lose counts. Slim the ISR now.')
    elif W >= tick:
        print('RESULT: OK for timekeeping (worst %d < hard %d), but the worst tick'
              % (W, hard))
        print('        consumes %d%% of one tick -> no CPU for the main loop on that'
              % round(100.0 * W / tick))
        print('        tick. Fine as long as the typical path (c) stays well under 100%.')
    else:
        print('RESULT: SAFE -- worst case fits inside one tick with %d cycles to spare.'
              % (tick - W))
    return 0


if __name__ == '__main__':
    sys.exit(main())
