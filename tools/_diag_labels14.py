import sys
sys.path.insert(0, 'tools')
from pdf_vector import load_objects, extract, make_raster

PDF = r'原始资料\2023TO学生\2023TO学生\3 原理图及元器件清单\1.主板、底板原理图合一.pdf'
_, streams, dicts = load_objects(PDF)
ras = make_raster([0, 0, 595.22, 842], 90, 4250, 3004)

_, _, labels, _ = extract(streams, [14])
print(f'stream 14: {len(labels)} labels')
for (ox, oy, em, g, f, text) in labels:
    x, y = ras(ox, oy)
    flag = '  <== VCCBAT 应该在这里' if 2040 < x < 2260 and 255 < y < 305 else ''
    print(f'  ({x:8.1f},{y:8.1f}) em={em:6.3f} g={g:5.3f} {f:<4} "{text}"{flag}')

print()
print('=== 用同样的 Tm 手动算一遍 VCCBAT 的位置 ===')
# BT 0 4.4119 -4.4102 0 57.18 417.2305 Tm .148 g -.015 Tc [(VC)...(AT)]TJ ET
print('  Tm 原点 (57.18, 417.2305) -> device', ras(57.18, 417.2305))
