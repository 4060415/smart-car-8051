import importlib.util as u
import sys

print('python', sys.version.split()[0])
for m in ['fitz', 'pypdf', 'PyPDF2', 'pdfminer', 'pdfplumber', 'reportlab', 'numpy', 'PIL', 'fontTools']:
    spec = None
    try:
        spec = u.find_spec(m)
    except Exception:
        pass
    print(f'{m:12} {"YES" if spec else "no"}')
