# -*- coding: utf-8 -*-
"""Markdown -> Word 可直接打开的 HTML（纯标准库，无第三方依赖）。

用法:
    python md_to_word_html.py <in.md> <out.htm>

为什么不用 python-docx:
    这台机器的 pip 装不上（沙箱临时目录权限 + PyPI 超时），而 Word 打开 .htm
    能完整保留标题与表格，复制粘贴到 .docx 里格式不丢。零依赖更可靠。

支持的语法（够本项目用）:
    标题 # ## ###、粗体 **x**、行内代码 `x`、代码块 ```、引用 >、
    无序/有序列表、GFM 表格、水平线 ---
"""
import html
import re
import sys


def inline(text: str) -> str:
    text = html.escape(text, quote=False)
    text = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', text)
    text = re.sub(r'`([^`]+)`', r'<code>\1</code>', text)
    return text


def table_html(rows):
    head, body = rows[0], rows[2:]
    out = ['<table border="1" cellspacing="0" cellpadding="4" '
           'style="border-collapse:collapse;border:1px solid #808080">']
    out.append('<tr>' + ''.join(
        '<td style="border:1px solid #808080;background:#EFEFEF"><b>%s</b></td>' % inline(c)
        for c in head) + '</tr>')
    for r in body:
        out.append('<tr>' + ''.join(
            '<td style="border:1px solid #808080">%s</td>' % inline(c) for c in r) + '</tr>')
    out.append('</table><p></p>')
    return '\n'.join(out)


def split_row(line: str):
    line = line.strip()
    if line.startswith('|'):
        line = line[1:]
    if line.endswith('|'):
        line = line[:-1]
    return [c.strip() for c in line.split('|')]


def convert(md: str) -> str:
    lines = md.splitlines()
    out = []
    i = 0
    while i < len(lines):
        ln = lines[i]

        if ln.startswith('```'):
            i += 1
            buf = []
            while i < len(lines) and not lines[i].startswith('```'):
                buf.append(lines[i])
                i += 1
            i += 1
            out.append('<pre style="font-family:Consolas,monospace;background:#F5F5F5;'
                       'border:1px solid #C0C0C0;padding:6px">%s</pre>'
                       % html.escape('\n'.join(buf)))
            continue

        if ln.startswith('|') and i + 1 < len(lines) and re.match(r'^\|[\s:|-]+\|$', lines[i + 1].strip()):
            rows = []
            while i < len(lines) and lines[i].strip().startswith('|'):
                rows.append(split_row(lines[i]))
                i += 1
            out.append(table_html(rows))
            continue

        m = re.match(r'^(#{1,6})\s+(.*)$', ln)
        if m:
            lvl = len(m.group(1))
            out.append('<h%d>%s</h%d>' % (lvl, inline(m.group(2)), lvl))
            i += 1
            continue

        if re.match(r'^-{3,}$', ln.strip()):
            out.append('<hr>')
            i += 1
            continue

        if ln.startswith('>'):
            buf = []
            while i < len(lines) and lines[i].startswith('>'):
                buf.append(lines[i].lstrip('>').strip())
                i += 1
            out.append('<blockquote style="border-left:3px solid #B0B0B0;margin-left:0;'
                       'padding-left:10px;color:#333333">%s</blockquote>'
                       % '<br>'.join(inline(b) for b in buf))
            continue

        m = re.match(r'^\s*[-*]\s+(.*)$', ln)
        if m:
            items = []
            while i < len(lines) and re.match(r'^\s*[-*]\s+', lines[i]):
                items.append(re.sub(r'^\s*[-*]\s+', '', lines[i]))
                i += 1
            out.append('<ul>' + ''.join('<li>%s</li>' % inline(x) for x in items) + '</ul>')
            continue

        m = re.match(r'^\s*(\d+)\.\s+(.*)$', ln)
        if m:
            items = []
            while i < len(lines) and re.match(r'^\s*\d+\.\s+', lines[i]):
                items.append(re.sub(r'^\s*\d+\.\s+', '', lines[i]))
                i += 1
            out.append('<ol>' + ''.join('<li>%s</li>' % inline(x) for x in items) + '</ol>')
            continue

        if not ln.strip():
            i += 1
            continue

        out.append('<p>%s</p>' % inline(ln))
        i += 1
    return '\n'.join(out)


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    src = open(sys.argv[1], encoding='utf-8').read()
    body = convert(src)
    doc = ('<!DOCTYPE html>\n<html><head><meta charset="utf-8">'
           '<title>%s</title></head>\n<body style="font-family:SimSun,serif;font-size:11pt;'
           'line-height:1.5">\n%s\n</body></html>\n'
           % (html.escape(sys.argv[1]), body))
    open(sys.argv[2], 'w', encoding='utf-8').write(doc)
    print('wrote %s (%d chars)' % (sys.argv[2], len(doc)))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
