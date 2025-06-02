import os
import re

REF_DIR = r"assets/tiles/dominos-ref"
OUT_DIR = r"assets/tiles/dominos-new"
SVG_SIZE = 40
DOMINO_WIDTH = 82
DOMINO_HEIGHT = 42
DOMINO_WIDTH_V = 42
DOMINO_HEIGHT_V = 82

def extract_svg_content(svg_path):
    with open(svg_path, encoding="utf-8") as f:
        content = f.read()
    rect_match = re.search(r'(<rect[^>]+/>)', content)
    circles = re.findall(r'(<circle[^>]+/>)', content)
    return rect_match.group(1), circles

def make_domino_svg(n, m, orientation):
    left_rect, left_circles = extract_svg_content(os.path.join(REF_DIR, f"domino-{n}-flat-arranged.svg"))
    right_rect, right_circles = extract_svg_content(os.path.join(REF_DIR, f"domino-{m}-flat-arranged.svg"))

    if orientation in ("left", "right"):
        width, height = DOMINO_WIDTH, DOMINO_HEIGHT
        if orientation == "left":
            left_face, right_face = (n, left_rect, left_circles), (m, right_rect, right_circles)
        else:
            left_face, right_face = (m, right_rect, right_circles), (n, left_rect, left_circles)
        svg = [
            '<?xml version="1.0" encoding="UTF-8"?>',
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" version="1.1">',
            f'  <rect style="fill:#000000;stroke-width:0" width="{width}" height="{height}" x="0" y="0"/>',
            '  <g transform="translate(0,1)">',
            f'    {left_face[1]}',
            *(f'    {c}' for c in left_face[2]),
            '  </g>',
            '  <g transform="translate(42,1)">',
            f'    {right_face[1]}',
            *(f'    {c}' for c in right_face[2]),
            '  </g>',
            '</svg>'
        ]
    else:
        width, height = DOMINO_WIDTH_V, DOMINO_HEIGHT_V
        if orientation == "top":
            top_face, bottom_face = (n, left_rect, left_circles), (m, right_rect, right_circles)
        else:
            top_face, bottom_face = (m, right_rect, right_circles), (n, left_rect, left_circles)
        svg = [
            '<?xml version="1.0" encoding="UTF-8"?>',
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" version="1.1">',
            f'  <rect style="fill:#000000;stroke-width:0" width="{width}" height="{height}" x="0" y="0"/>',
            '  <g transform="translate(1,0)">',
            f'    {top_face[1]}',
            *(f'    {c}' for c in top_face[2]),
            '  </g>',
            '  <g transform="translate(1,42)">',
            f'    {bottom_face[1]}',
            *(f'    {c}' for c in bottom_face[2]),
            '  </g>',
            '</svg>'
        ]
    return "\n".join(svg)

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    orientations = ["left", "right", "top", "bottom"]
    for n in range(0, 19):
        for m in range(0, n+1):
            for orientation in orientations:
                out_path = os.path.join(OUT_DIR, f"domino-{n}-{m}-{orientation}.svg")
                svg = make_domino_svg(n, m, orientation)
                with open(out_path, "w", encoding="utf-8") as f:
                    f.write(svg)
    print("All rotated dominoes generated.")

if __name__ == "__main__":
    main()