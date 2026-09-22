# -*- coding: utf-8 -*-
"""Smoke test for tools/docx_kit.py: text + table + images -> docx, then PDF."""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
from docx_kit import Docx  # noqa: E402

PHOTOS = os.path.join(ROOT, "现场照片")
pics = sorted(os.listdir(PHOTOS))
out = os.path.join(ROOT, "docs", "_hw_report_src", "_smoke.docx")

d = Docx(title="docx_kit smoke test", subject="test")
d.h1("docx_kit 冒烟测试")
d.body("这是一段正文，用来验证宋体、首行缩进与行距是否正常。数字与英文：STC89C52RC @11.0592 MHz, code=1771 B。")
d.table(["项目", "取值", "说明"],
        [["MCU", "STC89C52RC", "8 KB Flash"],
         ["晶振", "11.0592 MHz", "机器周期 1.0851 µs"],
         ["代码体积", "1771 B", "Eval 上限 2048 B"]],
        [3.0, 4.0, 7.6], caption="表 1 冒烟测试表")
d.image(os.path.join(PHOTOS, pics[0]), width_cm=7.6, caption="图 1 冒烟测试图（单张）")
d.page_break()
d.h2("第二页：并排图")
d.image_row([(os.path.join(PHOTOS, pics[1]), "（a）左"),
             (os.path.join(PHOTOS, pics[2]), "（b）右")], caption="图 2 冒烟测试图（并排）")
d.save(out)
print("written:", out, os.path.getsize(out), "bytes; photos:", len(pics))
