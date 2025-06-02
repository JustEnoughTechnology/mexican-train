import os
from pathlib import Path
from xml.etree import ElementTree as ET

# Paths
REF_DIR = Path('assets/tiles/dominos-ref')
OUT_DIR = Path('assets/tiles/dominos-new')
OUT_DIR.mkdir(parents=True, exist_ok=True)

# SVG template for a domino
SVG_TEMPLATE = '''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="82" height="42" viewBox="0 0 82 42" version="1.1">
  <rect style="fill:#000000;stroke-width:0" width="82" height="42" x="0" y="0"/>
  <g transform="translate(0,1)">
    {left_content}
  </g>
  <g transform="translate(42,1)">
    {right_content}
  </g>
</svg>'''

def extract_inner_svg(svg_path):
    """Extracts the inner SVG content (rect and circles) from a flat-arranged SVG file."""
    tree = ET.parse(svg_path)
    root = tree.getroot()
    # Remove XML namespace for easier tag matching
    for elem in root.iter():
        if '}' in elem.tag:
            elem.tag = elem.tag.split('}', 1)[1]
    # Only keep <rect> and <circle> elements
    content = []
    for child in root:
        if child.tag in ('rect', 'circle'):
            content.append(ET.tostring(child, encoding='unicode'))
    return '\n    '.join(content)

def main():
    for left in range(18, -1, -1):
        for right in range(left, -1, -1):
            left_file = REF_DIR / f'domino-{left}-flat-arranged.svg'
            right_file = REF_DIR / f'domino-{right}-flat-arranged.svg'
            if not left_file.exists() or not right_file.exists():
                print(f"Missing: {left_file} or {right_file}")
                continue
            left_content = extract_inner_svg(left_file)
            right_content = extract_inner_svg(right_file)
            svg = SVG_TEMPLATE.format(left_content=left_content, right_content=right_content)
            out_path = OUT_DIR / f'domino-{left}-{right}.svg'
            with open(out_path, 'w', encoding='utf-8') as f:
                f.write(svg)
            print(f"Wrote {out_path}")

if __name__ == '__main__':
    main()
