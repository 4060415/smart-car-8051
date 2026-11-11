# -*- coding: utf-8 -*-
"""把 firmware/c51/main.c 生成一份「带解析的 C 语言阅读版」Markdown。

用法:  python tools/mk_main_doc.py
输出:  docs/主程序_带解析.md

★ 只读源码、绝不修改 main.c。
★ 全文逐行带行号，方便和 main.c 对照；每节按源码自己的 `/*===` 分节标题切分。
★ 解析内容来自两处：① 源码里本来就写得很细的中文注释；② 本文前面
   「程序结构总览 / 函数索引 / 关键机制导读」三张导航表（脚本生成 + 手写导读）。
"""
import hashlib
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'firmware', 'c51', 'main.c')
HEX = os.path.join(ROOT, 'firmware', 'c51', 'main.hex')
OUT = os.path.join(ROOT, 'docs', '主程序_带解析.md')

SEC_RE = re.compile(r'^ \* ([一二三四五六七八九十百]+)、(.+?)\s*$')
FUNC_RE = re.compile(
    r'^(?:static\s+)?(?:void|bit|char|int|unsigned\s+char|unsigned\s+int'
    r'|unsigned\s+long)\s+(\w+)\s*\(')


def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as fh:
        for chunk in iter(lambda: fh.read(65536), b''):
            h.update(chunk)
    return h.hexdigest().upper()


def hex_code_bytes(path):
    total = 0
    if not os.path.exists(path):
        return 0
    with open(path, 'r', encoding='ascii', errors='ignore') as fh:
        for line in fh:
            line = line.strip()
            if len(line) >= 11 and line[0] == ':':
                total += int(line[1:3], 16)
    return total


def main():
    with open(SRC, 'r', encoding='utf-8') as fh:
        lines = fh.read().splitlines()

    # ---- 分节：`/*====` 后面紧跟 ` * 中文数字、标题` ----
    sections = []          # [(start_line_no_1based, title)]
    for i in range(len(lines) - 1):
        if lines[i].startswith('/*==='):
            m = SEC_RE.match(lines[i + 1])
            if m:
                sections.append((i + 1, m.group(1) + '、' + m.group(2)))
    if not sections:
        sys.exit('没找到分节标题，源码格式变了？')

    # ---- 函数：顶格的函数定义（排除原型声明）----
    funcs = []             # [(line_no, name)]
    for i, ln in enumerate(lines):
        if ln.startswith('}') or ln.startswith(' ') or ln.startswith('\t'):
            continue
        m = FUNC_RE.match(ln)
        if m and not ln.rstrip().endswith(';'):
            funcs.append((i + 1, m.group(1)))

    def section_of(lineno):
        cur = sections[0][1]
        for start, title in sections:
            if start <= lineno:
                cur = title
            else:
                break
        return cur

    src_hash = sha256(SRC)
    hex_hash = sha256(HEX) if os.path.exists(HEX) else '(no hex)'
    code = hex_code_bytes(HEX)

    out = []
    w = out.append

    # ================= 文档头 =================
    w('# 主程序 C 语言阅读版（`firmware\\c51\\main.c` 全文 + 解析）')
    w('')
    w('> **这是什么**：整份主程序 `main.c` 的**逐行全文**，外加三张导航表'
      '（结构总览 / 函数索引 / 关键机制导读）。')
    w('> 全文由 `tools\\mk_main_doc.py` 从源码直接抄出，**没有改写、没有省略**。')
    w('>')
    w('> **快照指纹**：'
      '`main.c` SHA256 `%s`' % src_hash)
    w('> `main.hex` SHA256 `%s`，**code = %d B**' % (hex_hash, code))
    w('>')
    w('> ⚠️ **这是快照**：行号与内容都对应上面那个 `main.c` 指纹。'
      '源码一改本文立刻过期，**验收始终以 `main.c` 为准**。')
    w('>')
    w('> **怎么读**：先看 §一 结构总览定位，再看 §二 函数索引找具体函数，'
      '然后翻到 §四 对应小节看逐行代码 —— 源码里的中文注释本身就是最细的解析。')
    w('')
    w('---')
    w('')

    # ================= 一、结构总览 =================
    w('## 一、程序结构总览（%d 节）' % len(sections))
    w('')
    w('| # | 小节 | 起始行 | 行数 |')
    w('|---|---|---|---|')
    for idx, (start, title) in enumerate(sections):
        end = sections[idx + 1][0] - 1 if idx + 1 < len(sections) else len(lines)
        w('| %d | %s | L%d | %d |' % (idx + 1, title, start, end - start + 1))
    w('| — | **合计** | — | **%d 行** |' % len(lines))
    w('')

    # ================= 二、函数索引 =================
    w('## 二、函数索引（%d 个顶格函数定义）' % len(funcs))
    w('')
    w('| 函数 | 行 | 所在小节 |')
    w('|---|---|---|')
    for lineno, name in funcs:
        w('| `%s()` | L%d | %s |' % (name, lineno, section_of(lineno)))
    w('')

    # ================= 三、关键机制导读 =================
    w('## 三、关键机制导读')
    w('')
    w('> 这一节是**人写的导航**，不是源码；详细口径一律以 §四 的源码注释为准。')
    w('')
    w('| 机制 | 在哪一节 | 一句话 |')
    w('|---|---|---|')
    w('| 时基与节拍 | 十四、十五 | T0 每 99.83µs 中断一次（1 tick），'
      '中断里顺带做软件 PWM、蜂鸣器方波、10ms 节拍 |')
    w('| 电机统一出口 | 十九 | 所有动作都走 `motor_set(动作码, 档位)`，'
      '**避障闸门只在这一个地方改写动作或刹停** |')
    w('| 超声波测距 | 二十八 | 完全非阻塞：主循环发触发、中断数回波宽度，'
      '读数 60ms 一更新 |')
    w('| 车头红外 | 二十九、三十 | 量程只有 1~2cm，极性写死在 `IR_INV_FORCE`；'
      '触发就走"倒车 + 原地右转"机动 |')
    w('| 避障机动 | 三十 | `av_mnv` 控制的两段状态机：'
      '`AV_BACK`（固定倒 0.5s）→ `AV_ATURN`（原地右转 1.0s），'
      '最多连做 3 轮，寻光模式整体关闭 |')
    w('| 遥控解码 | 三十二、三十三 | NEC 协议，靠量电平持续时长；'
      'P3.3 下降沿 + 定时器计时 |')
    w('| 模式状态机 | 二十五、四十、四十一 | 手动 / 寻光 / 循迹 / 回放；'
      '手动走遥控，其余走各自的自动动作 |')
    w('| 录制回放 | 三十八、三十九 | 最多 80 条 `(动作, 档位, 时长)`；'
      '回放不吃避障，遇障停车不绕行 |')
    w('| 显示 | 二十一 | P2 数码管段码 + `d3_mix()` 统一处理 D3 指示灯 |')
    w('')
    w('### 本轮改动编号索引（C17 ~ C25）')
    w('')
    w('| 编号 | 内容 |')
    w('|---|---|')
    w('| C17 | 避障分级：弧线档 + 决策保持 280ms |')
    w('| C18 | 车头红外触发改为"倒车 + 原地右转"机动（新状态 `AV_BACK`/`AV_ATURN`）|')
    w('| C19 | 超声波量程上限与分档门限拆开（`US_RANGE`/`US_REL`），退出避让加滞回 |')
    w('| C20 | 倒车段改为固定计时，不再用超声判距离 |')
    w('| C21 | 机动自带倒车档位（`AV_BACK_GEAR`），不再依赖用户档位 |')
    w('| C22 | 车头红外极性写死（`IR_INV_FORCE`），不再上电自校准 |')
    w('| C23 | 转弯段加长到 1.0s |')
    w('| C24 | 一次遭遇最多 3 轮机动；只有方向键中止机动；录制中不机动；'
      '板上加减档不抢电机 |')
    w('| C25 | 寻光模式关闭全部避障（`AV_OFF_IN_LIGHT`）|')
    w('')

    # ================= 四、全文 =================
    w('---')
    w('')
    w('## 四、全文（逐行，按源码分节切分）')
    w('')
    for idx, (start, title) in enumerate(sections):
        end = sections[idx + 1][0] - 1 if idx + 1 < len(sections) else len(lines)
        w('### %d、%s' % (idx + 1, title))
        w('')
        w('> L%d – L%d（%d 行）' % (start, end, end - start + 1))
        w('')
        w('```c')
        for n in range(start, end + 1):
            w('%4d| %s' % (n, lines[n - 1]))
        w('```')
        w('')

    text = '\n'.join(out) + '\n'
    with open(OUT, 'w', encoding='utf-8', newline='\r\n') as fh:
        fh.write(text)

    print('OK  %s' % OUT)
    print('    sections=%d  functions=%d  source_lines=%d  code=%dB'
          % (len(sections), len(funcs), len(lines), code))


if __name__ == '__main__':
    main()
