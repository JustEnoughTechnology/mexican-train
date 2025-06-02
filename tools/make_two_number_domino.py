import os
from lxml import etree

SRC_DIR = os.path.join("assets", "tiles", "dominos-ref")
DST_DIR = os.path.join("assets", "tiles", "dominos-new")

def extract_inner_group(svg_path):
    tree = etree.parse(svg_path)
    root = tree.getroot()
    # Find the first <g> inside the root <g> (skip the outermost group)
    for g in root.findall('.//{http://www.w3.org/2000/svg}g'):
        if g.attrib.get('id', '').startswith('g'):
            return g
    return None

def make_two_number_domino(left_num, right_num, out_name):
    os.makedirs(DST_DIR, exist_ok=True)
    left_svg = os.path.join(SRC_DIR, f"domino-{left_num}.svg")
    right_svg = os.path.join(SRC_DIR, f"domino-{right_num}.svg")
    out_svg = os.path.join(DST_DIR, out_name)

    # SVG size constants (from your files)
    width = 82.0
    height = 40.0
    gap = 2.0  # 2 pixel gap between the two halves
    half_width = (width - gap) / 2

    # Create root SVG
    NSMAP = {
        None: "http://www.w3.org/2000/svg",
        "inkscape": "http://www.inkscape.org/namespaces/inkscape",
        "sodipodi": "http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
    }
    svg = etree.Element("svg", nsmap=NSMAP)
    svg.set("width", str(width))
    svg.set("height", str(height))
    svg.set("viewBox", f"0 0 {width} {height}")
    svg.set("version", "1.1")

    # Black background
    bg = etree.SubElement(svg, "rect")
    bg.set("x", "0")
    bg.set("y", "0")
    bg.set("width", str(width))
    bg.set("height", str(height))
    bg.set("style", "fill:black;stroke:black")

    # Left half (number 6)
    left_g = extract_inner_group(left_svg)
    left_g_copy = etree.fromstring(etree.tostring(left_g))
    # Scale and move to left half
    left_g_copy.set("transform", f"matrix({half_width/40.0},0,0,{height/40.0},0,0)")
    svg.append(left_g_copy)

    # Right half (number 5)
    right_g = extract_inner_group(right_svg)
    right_g_copy = etree.fromstring(etree.tostring(right_g))
    # Scale and move to right half
    right_g_copy.set("transform", f"matrix({half_width/40.0},0,0,{height/40.0},{half_width+gap},0)")
    svg.append(right_g_copy)

    # Write output
    with open(out_svg, "wb") as f:
        f.write(etree.tostring(svg, pretty_print=True, xml_declaration=True, encoding="utf-8"))

    print(f"Created {out_svg}")

if __name__ == "__main__":
    make_two_number_domino(6, 5, "domino-6-5.svg")
