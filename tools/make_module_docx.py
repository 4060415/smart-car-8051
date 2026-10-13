# -*- coding: utf-8 -*-
"""把 模块程序/*.c 参考文件转成带注释配色的 .docx（只用 Python 标准库，无需安装任何包）。

导出时会自动加上作者身份标识（三处）：
    ① .c 文件头注释
    ② docx 标题下方一行
    ③ docx 每页页眉

用法：
    python tools\\make_module_docx.py                        # 默认转 模块程序\\运动程序.c
    python tools\\make_module_docx.py 模块程序\\避障程序.c
    python tools\\make_module_docx.py 模块程序\\避障程序.c 模块程序\\避障.docx 避障程序

第 4 个参数可覆盖标题下的「说明」行，例如整份固件源码：
    python tools\\make_module_docx.py firmware\\c51\\main.c firmware\\c51\\main.docx "C51 主程序 main.c" "说明：..." --no-c-header

若某个文件不想让脚本动它的 .c 文件头，加 --no-c-header：
    python tools\\make_module_docx.py 模块程序\\避障程序.c --no-c-header
"""
import os
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# ---- 作者身份标识（要改就改这里，所有导出都会跟着变）----
IDENT_NAME = '李家乐'
IDENT_ID = '03231312'
IDENT_LINE = '姓名：%s　　学号：%s' % (IDENT_NAME, IDENT_ID)

# 默认说明行（可用命令行第 4 个参数覆盖）
DEFAULT_NOTE = '说明：本文件从 firmware\\c51\\main.c 中摘出，仅供查阅，不参与固件编译。'

CODE_FONT = 'Consolas'
CJK_FONT = '宋体'
UI_FONT = '微软雅黑'
COMMENT_COLOR = '2E7D32'

W_NS = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
R_NS = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'
PKG_REL_NS = 'http://schemas.openxmlformats.org/package/2006/relationships'


def esc(s):
    return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


def rpr(is_comment=False, bold=False, size=18, font=CODE_FONT):
    east = CJK_FONT if font == CODE_FONT else UI_FONT
    parts = ['<w:rFonts w:ascii="%s" w:eastAsia="%s" w:hAnsi="%s"/>' % (font, east, font)]
    if bold:
        parts.append('<w:b/>')
    parts.append('<w:sz w:val="%d"/><w:szCs w:val="%d"/>' % (size, size))
    if is_comment:
        parts.append('<w:color w:val="%s"/>' % COMMENT_COLOR)
    return '<w:rPr>' + ''.join(parts) + '</w:rPr>'


def run(text, size=18, bold=False, font=UI_FONT, color=None):
    extra = '<w:color w:val="%s"/>' % color if color else ''
    return ('<w:r><w:rPr><w:rFonts w:ascii="%s" w:eastAsia="%s" w:hAnsi="%s"/>%s%s'
            '<w:sz w:val="%d"/><w:szCs w:val="%d"/></w:rPr>'
            '<w:t xml:space="preserve">%s</w:t></w:r>'
            % (font, CJK_FONT if font == CODE_FONT else UI_FONT, font, '<w:b/>' if bold else '',
               extra, size, size, esc(text)))


def code_para(runs, size=18):
    ppr = ('<w:pPr><w:spacing w:before="0" w:after="0" w:line="240" w:lineRule="auto"/>'
           '<w:shd w:val="clear" w:color="auto" w:fill="F7F7F7"/>'
           + rpr(size=size) + '</w:pPr>')
    body = ''
    if not runs:
        body = '<w:r>' + rpr(size=size) + '<w:t xml:space="preserve"> </w:t></w:r>'
    for text, is_comment in runs:
        body += ('<w:r>' + rpr(is_comment=is_comment, size=size)
                 + '<w:t xml:space="preserve">' + esc(text) + '</w:t></w:r>')
    return '<w:p>' + ppr + body + '</w:p>'


def head_para(text, size=22, bold=True, center=False, after=60, font=UI_FONT, color=None):
    jc = '<w:jc w:val="center"/>' if center else ''
    ppr = '<w:pPr>%s<w:spacing w:before="0" w:after="%d"/></w:pPr>' % (jc, after)
    return '<w:p>' + ppr + run(text, size=size, bold=bold, font=font, color=color) + '</w:p>'


def split_runs(line, in_block):
    """把一行源码切成 [(文本, 是否是注释), ...]。"""
    runs, buf, i, n = [], '', 0, len(line)
    while i < n:
        if in_block:
            end = line.find('*/', i)
            if end == -1:
                buf += line[i:]
                i = n
            else:
                buf += line[i:end + 2]
                i = end + 2
                in_block = False
                if buf:
                    runs.append((buf, True))
                    buf = ''
        else:
            cands = [j for j in (line.find('//', i), line.find('/*', i)) if j != -1]
            if not cands:
                buf += line[i:]
                i = n
            else:
                j = min(cands)
                if j > i:
                    runs.append((line[i:j], False))
                if line[j:j + 2] == '//':
                    runs.append((line[j:], True))
                    i = n
                else:
                    in_block = True
                    i = j
    if buf:
        runs.append((buf, in_block))
    return runs, in_block


def ensure_c_header(path, title):
    """把身份标识块写到 .c 文件最前面（已经有就不重复加）。返回是否写入。"""
    with open(path, 'r', encoding='utf-8', newline='') as f:
        text = f.read()
    if IDENT_ID in text[:800]:
        return False
    top = ('/*=========================================================================\n'
           ' * %s\n'
           ' * %s\n'
           ' *=========================================================================*/\n\n'
           % (title, IDENT_LINE))
    with open(path, 'w', encoding='utf-8', newline='') as f:
        f.write(top + text)
    return True


def build(src, out, title, note=DEFAULT_NOTE):
    with open(src, 'r', encoding='utf-8', newline='') as f:
        lines = f.read().replace('\r\n', '\n').split('\n')
    while lines and lines[-1].strip() == '':
        lines.pop()

    body = [head_para(title, size=32, center=True, after=40),
            head_para(IDENT_LINE, size=22, bold=True, center=True, after=40),
            head_para('芯片：STC89C52RC　　晶振：11.0592 MHz　　编译器：Keil C51',
                      size=20, bold=False, after=20),
            head_para(note, size=20, bold=False, after=120)]

    in_block = False
    for ln in lines:
        runs, in_block = split_runs(ln, in_block)
        body.append(code_para(runs))

    # sectPr：headerReference 必须排在 pgSz/pgMar 前面
    sect = ('<w:sectPr>'
            '<w:headerReference w:type="default" r:id="rId1"/>'
            '<w:pgSz w:w="11906" w:h="16838"/>'
            '<w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134" '
            'w:header="851" w:footer="992" w:gutter="0"/>'
            '</w:sectPr>')

    document = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\r\n'
                '<w:document xmlns:w="%s" xmlns:r="%s">'
                '<w:body>' % (W_NS, R_NS) + ''.join(body) + sect + '</w:body></w:document>')

    header = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\r\n'
              '<w:hdr xmlns:w="%s">'
              '<w:p><w:pPr><w:pBdr>'
              '<w:bottom w:val="single" w:sz="6" w:space="1" w:color="BFBFBF"/>'
              '</w:pBdr><w:jc w:val="center"/></w:pPr>'
              '%s</w:p></w:hdr>'
              % (W_NS, run(IDENT_LINE, size=18, font=UI_FONT, color='595959')))

    doc_rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\r\n'
                '<Relationships xmlns="%s">'
                '<Relationship Id="rId1" Type="%s/header" Target="header1.xml"/>'
                '</Relationships>' % (PKG_REL_NS, R_NS))

    pkg_rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\r\n'
                '<Relationships xmlns="%s">'
                '<Relationship Id="rId1" Type="%s/officeDocument" Target="word/document.xml"/>'
                '</Relationships>' % (PKG_REL_NS, R_NS))

    content_types = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\r\n'
                     '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
                     '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
                     '<Default Extension="xml" ContentType="application/xml"/>'
                     '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
                     '<Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/>'
                     '</Types>')

    if os.path.exists(out):
        os.remove(out)
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
        z.writestr('[Content_Types].xml', content_types.encode('utf-8'))
        z.writestr('_rels/.rels', pkg_rels.encode('utf-8'))
        z.writestr('word/_rels/document.xml.rels', doc_rels.encode('utf-8'))
        z.writestr('word/document.xml', document.encode('utf-8'))
        z.writestr('word/header1.xml', header.encode('utf-8'))
    return len(lines)


def main():
    args = [a for a in sys.argv[1:] if a != '--no-c-header']
    want_c_header = '--no-c-header' not in sys.argv[1:]

    src = args[0] if args else os.path.join('模块程序', '运动程序.c')
    if not os.path.isabs(src):
        src = os.path.join(ROOT, src)
    if len(args) >= 2:
        out = args[1]
        if not os.path.isabs(out):
            out = os.path.join(ROOT, out)
    else:
        out = os.path.splitext(src)[0] + '.docx'
    title = args[2] if len(args) >= 3 else os.path.splitext(os.path.basename(src))[0]
    note = args[3] if len(args) >= 4 else DEFAULT_NOTE

    if not os.path.isfile(src):
        print('NOT FOUND: ' + src)
        return 1

    added = ensure_c_header(src, title) if want_c_header else False
    n = build(src, out, title, note)
    print('OK %s  bytes=%d lines=%d  ident=%s  c_header=%s'
          % (out, os.path.getsize(out), n, IDENT_ID, 'added' if added else 'present/skipped'))
    return 0


if __name__ == '__main__':
    sys.exit(main())
