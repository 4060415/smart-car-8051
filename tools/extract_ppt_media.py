# -*- coding: utf-8 -*-
"""把课程 PPT 里的图片全部导出，并生成"幻灯片 -> 图片"对照表。

用法: python extract_ppt_media.py <outdir> <ppt1> [ppt2 ...]

产物:
  <outdir>/<ppt名>/media/<原文件名>      导出的图片
  <outdir>/<ppt名>/_map.txt             每页幻灯片的标题与所用图片
"""
import os
import re
import shutil
import sys
import zipfile
from xml.etree import ElementTree as ET

NS = {
    'a': 'http://schemas.openxmlformats.org/drawingml/2006/main',
    'r': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
}


def slide_num(name: str) -> int:
    m = re.search(r'slide(\d+)\.xml$', name)
    return int(m.group(1)) if m else 0


def slide_title(xml: str) -> str:
    """取该页第一个非空文本段落作为标题（PPT 的文字层通常只有标题）。"""
    try:
        root = ET.fromstring(xml)
    except ET.ParseError:
        return '?'
    for para in root.iter('{http://schemas.openxmlformats.org/drawingml/2006/main}p'):
        text = ''.join(t.text or '' for t in para.iter(
            '{http://schemas.openxmlformats.org/drawingml/2006/main}t'))
        text = text.strip()
        if text:
            return text
    return '(无文字)'


def rels_images(z: zipfile.ZipFile, slide: str):
    """解析 slideN.xml.rels，返回该页引用的 media 文件（保持出现顺序）。"""
    rels_name = 'ppt/slides/_rels/%s.rels' % os.path.basename(slide)
    if rels_name not in z.namelist():
        return []
    root = ET.fromstring(z.read(rels_name))
    out = []
    for rel in root:
        target = rel.get('Target', '')
        if 'media/' in target:
            out.append('ppt/' + target.replace('../', ''))
    return out


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    outdir = sys.argv[1]
    for ppt in sys.argv[2:]:
        stem = os.path.splitext(os.path.basename(ppt))[0]
        base = os.path.join(outdir, stem)
        mediadir = os.path.join(base, 'media')
        os.makedirs(mediadir, exist_ok=True)
        lines = []
        with zipfile.ZipFile(ppt) as z:
            # 1) 导出全部 media
            count = 0
            for entry in z.namelist():
                if entry.startswith('ppt/media/') and not entry.endswith('/'):
                    name = os.path.basename(entry)
                    with z.open(entry) as src, open(os.path.join(mediadir, name), 'wb') as dst:
                        shutil.copyfileobj(src, dst)
                    count += 1
            # 2) 每页幻灯片 -> 图片
            slides = sorted([n for n in z.namelist()
                             if re.match(r'ppt/slides/slide\d+\.xml$', n)], key=slide_num)
            for s in slides:
                title = slide_title(z.read(s).decode('utf-8', 'ignore'))
                imgs = [os.path.basename(i) for i in rels_images(z, s)]
                lines.append('slide%-3d | %-40s | %s' % (slide_num(s), title, ', '.join(imgs) or '(无图)'))
        with open(os.path.join(base, '_map.txt'), 'w', encoding='utf-8') as fh:
            fh.write('\n'.join(lines))
        print('%s -> %d 张图, %d 页幻灯片' % (stem, count, len(lines)))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
