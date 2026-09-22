import re
import sys
sys.path.insert(0, 'tools')
from pdf_vector import load_objects, extract, tokenize

PDF = r'原始资料\2023TO学生\2023TO学生\3 原理图及元器件清单\1.主板、底板原理图合一.pdf'
_, streams, dicts = load_objects(PDF)

for cid in [14, 15, 16, 17, 18, 19, 20, 21]:
    data = streams.get(cid, b'')
    t = data.decode('latin-1')
    bt = len(re.findall(r'\bBT\b', t))
    show = len(re.findall(r'(?:\)\s*Tj|\]\s*TJ)', t))
    _, _, labels, _ = extract(streams, [cid])
    print(f'stream {cid}: BT={bt:>3}  show-ops={show:>3}  labels extracted={len(labels):>3}')
    if len(labels) != show:
        print('   >>> MISMATCH -- dumping the ops in order:')
        for i, m in enumerate(re.finditer(r'\bBT\b.*?\bET\b', t, re.S)):
            blk = ' '.join(m.group(0).split())
            print(f'      [{i:>3}] {blk[:150]}')
        break
