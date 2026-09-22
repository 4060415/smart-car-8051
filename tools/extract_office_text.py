# -*- coding: utf-8 -*-
"""抽取 .pptx / .docx 的全部文本（纯标准库 zipfile），输出为 txt。
用法: python extract_office_text.py <in.pptx|in.docx> <out.txt>
"""
import re
import sys
import zipfile
from xml.etree import ElementTree as ET


def slide_key(name: str):
    m = re.search(r"(\d+)", name.rsplit("/", 1)[-1])
    return (0, int(m.group(1))) if m else (1, name)


def extract(path: str) -> str:
    parts = []
    with zipfile.ZipFile(path) as z:
        names = [n for n in z.namelist()
                 if re.match(r"ppt/slides/slide\d+\.xml$", n)
                 or re.match(r"word/document\.xml$", n)
                 or re.match(r"ppt/notesSlides/notesSlide\d+\.xml$", n)]
        names.sort(key=slide_key)
        for n in names:
            xml = z.read(n).decode("utf-8", "ignore")
            # 段落与换行
            xml = xml.replace("</a:p>", "\n").replace("</w:p>", "\n")
            xml = xml.replace("<a:br/>", "\n").replace("<w:br/>", "\n")
            xml = xml.replace("</a:tr>", "\n").replace("</w:tr>", "\n")
            xml = re.sub(r"</a:tc>", " | ", xml)
            text = re.sub(r"<[^>]+>", "", xml)
            text = text.replace("&lt;", "<").replace("&gt;", ">").replace("&amp;", "&")
            text = re.sub(r"\n{2,}", "\n", text)
            if text.strip():
                parts.append("=== %s ===\n%s" % (n, text.strip()))
    return "\n\n".join(parts)


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    text = extract(sys.argv[1])
    with open(sys.argv[2], "w", encoding="utf-8") as fh:
        fh.write(text)
    print("slides/sections: %d chars: %d -> %s" % (text.count("=== "), len(text), sys.argv[2]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
