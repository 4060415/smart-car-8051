# -*- coding: utf-8 -*-
"""从 PDF 中提取可读文本（纯标准库：zlib 解压内容流 + 提取 Tj/TJ 文本算子）。
用于读取课程套件的原理图 / 焊接图 / 元器件清单，抓取单片机引脚与网络名。
用法: python extract_pdf_text.py <file.pdf> [关键字...]
"""
import re
import sys
import zlib


def iter_streams(data: bytes):
    for m in re.finditer(rb"stream\r?\n", data):
        start = m.end()
        end = data.find(b"endstream", start)
        if end == -1:
            continue
        raw = data[start:end]
        for candidate in (raw, raw.rstrip(b"\r\n")):
            try:
                yield zlib.decompress(candidate)
                break
            except zlib.error:
                continue


def decode_text_ops(content: bytes) -> str:
    out = []
    # 括号字符串: (text) Tj  和  [(a) -20 (b)] TJ
    for m in re.finditer(rb"\((?:\\.|[^\\()])*\)", content):
        s = m.group(0)[1:-1]
        s = s.replace(b"\\(", b"(").replace(b"\\)", b")").replace(b"\\\\", b"\\")
        try:
            out.append(s.decode("latin-1"))
        except UnicodeDecodeError:
            pass
    # 十六进制字符串: <00480065> Tj
    for m in re.finditer(rb"<([0-9A-Fa-f\s]{4,})>", content):
        hexs = re.sub(rb"\s", b"", m.group(1))
        if len(hexs) % 4:
            continue
        chars = []
        for i in range(0, len(hexs), 4):
            try:
                code = int(hexs[i:i + 4], 16)
            except ValueError:
                continue
            if 32 <= code < 127:
                chars.append(chr(code))
        if chars:
            out.append("".join(chars))
    return "\n".join(out)


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    path = sys.argv[1]
    keys = sys.argv[2:]
    with open(path, "rb") as fh:
        data = fh.read()
    chunks = []
    for stream in iter_streams(data):
        if b"Tj" in stream or b"TJ" in stream or b"BT" in stream:
            chunks.append(decode_text_ops(stream))
    text = "\n".join(chunks)
    print("### 提取字符数:", len(text))
    if keys:
        lines = text.splitlines()
        for i, line in enumerate(lines):
            if any(k.lower() in line.lower() for k in keys):
                lo, hi = max(0, i - 3), min(len(lines), i + 4)
                print("---- 命中第 %d 行 ----" % (i + 1))
                print("\n".join(lines[lo:hi]))
    else:
        print(text[:20000])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
