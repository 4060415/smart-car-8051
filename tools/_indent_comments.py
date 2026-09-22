# -*- coding: utf-8 -*-
"""Indent comment-only blocks that sit inside functions (they were replaced at
column 0 because the original block also started there)."""
import re

SRC = r"firmware\c51\main.c"
lines = open(SRC, encoding="utf-8").read().split("\n")

i = 0
fixed = 0
while i < len(lines):
    s = lines[i].strip()
    if s.startswith("/*") or s.startswith("//"):
        if not lines[i].startswith((" ", "\t")):        # block at column 0
            j = i
            while j < len(lines) and (lines[j].strip().startswith(("/*", "*", "//")) or
                                      lines[j].strip() == ""):
                if lines[j].strip() == "" and j + 1 < len(lines) and \
                   not lines[j + 1].strip().startswith(("/*", "*", "//")):
                    break
                j += 1
            # indentation of the next real code line
            k = j
            while k < len(lines) and lines[k].strip() == "":
                k += 1
            ind = 0
            if k < len(lines) and not lines[k].startswith(("/*", "*", "//")):
                ind = len(lines[k]) - len(lines[k].lstrip(" "))
            if ind > 0:
                for x in range(i, j):
                    if lines[x].strip():
                        lines[x] = " " * ind + lines[x]
                        fixed += 1
            i = j
            continue
    i += 1

open(SRC, "w", encoding="utf-8", newline="").write("\n".join(lines))
print("indented comment lines:", fixed)
