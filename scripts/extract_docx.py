import sys
import zipfile
import xml.etree.ElementTree as ET

def docx_to_text(path):
    with zipfile.ZipFile(path) as z:
        xml = z.read('word/document.xml')
    # parse XML and extract text nodes
    root = ET.fromstring(xml)
    texts = []
    for paragraph in root.iter():
        tag = paragraph.tag
        if tag.endswith('}t') and paragraph.text:
            texts.append(paragraph.text)
        elif tag.endswith('}p'):
            texts.append('\n')
    return ''.join(texts)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: python extract_docx.py <path-to-docx>')
        sys.exit(1)
    path = sys.argv[1]
    try:
        text = docx_to_text(path)
        sys.stdout.write(text)
    except Exception as e:
        print('ERROR:', e)
        sys.exit(2)
