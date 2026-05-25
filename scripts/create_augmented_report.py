import sys
from pathlib import Path

BASE = Path(__file__).resolve().parent
SRC = BASE / 'report_text.txt'
ADD = BASE / 'report_additions.txt'
OUT_TXT = BASE / 'report_augmented.txt'
OUT_DOCX = Path(__file__).resolve().parents[1] / '1671020200 - ĐỒ ÁN TN - LÊ ĐỨC MẠNH_edited.docx'

def make_augmented_text():
    a = SRC.read_text(encoding='utf-8') if SRC.exists() else ''
    b = ADD.read_text(encoding='utf-8') if ADD.exists() else ''
    combined = a + '\n\n--- Phần bổ sung (tự động) ---\n\n' + b
    OUT_TXT.write_text(combined, encoding='utf-8')
    return combined

def try_create_docx(text: str):
    try:
        from docx import Document
    except Exception as e:
        print('python-docx not available:', e)
        return False
    doc = Document()
    for para in text.split('\n'):
        doc.add_paragraph(para)
    doc.save(str(OUT_DOCX))
    return True

if __name__ == '__main__':
    text = make_augmented_text()
    ok = try_create_docx(text)
    if ok:
        print('Created:', OUT_DOCX)
    else:
        print('Wrote augmented text to', OUT_TXT)
    sys.exit(0)
