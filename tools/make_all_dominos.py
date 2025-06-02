import os
import re

REF_DIR = r"assets/tiles/dominos-ref"
OUT_DIR = r"assets/tiles/dominos-new"
SVG_SIZE = 40
DOMINO_WIDTH = 82
DOMINO_HEIGHT = 42
GAP = 2

def extract_svg_content(svg_path):
    """Extracts the <rect> and all <circle> elements from a flat-arranged SVG."""
    with open(svg_path, encoding="utf-8") as f:
        content = f.read()
    rect_match = re.search(r'(<rect[^>]+/>)', content)
    circles = re.findall(r'(<circle[^>]+/>)', content)
    return rect_match.group(1), circles

def make_domino_svg(n, m):
    left_rect, left_circles = extract_svg_content(os.path.join(REF_DIR, f"domino-{n}-flat-arranged.svg"))
    right_rect, right_circles = extract_svg_content(os.path.join(REF_DIR, f"domino-{m}-flat-arranged.svg"))
    svg = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{DOMINO_WIDTH}" height="{DOMINO_HEIGHT}" viewBox="0 0 {DOMINO_WIDTH} {DOMINO_HEIGHT}" version="1.1">',
        '  <rect style="fill:#000000;stroke-width:0" width="82" height="42" x="0" y="0"/>',
        '  <g transform="translate(0,1)">',
        f'    {left_rect}',
        *(f'    {c}' for c in left_circles),
        '  </g>',
        '  <g transform="translate(42,1)">',
        f'    {right_rect}',
        *(f'    {c}' for c in right_circles),
        '  </g>',
        '</svg>'
    ]
    return "\n".join(svg)

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for n in range(0, 19):
        for m in range(0, n+1):
            out_path = os.path.join(OUT_DIR, f"domino-{n}-{m}.svg")
            svg = make_domino_svg(n, m)
            with open(out_path, "w", encoding="utf-8") as f:
                f.write(svg)
    print("All dominoes generated.")

if __name__ == "__main__":
    main()
