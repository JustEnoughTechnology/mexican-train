import os
from lxml import etree

SRC_DIR = os.path.join("assets", "tiles", "dominos-ref")

def find_svg_files(root_dir):
    svg_files = []
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.lower().endswith('.svg'):
                svg_files.append(os.path.join(dirpath, filename))
    return svg_files

def check_svg_structure(svg_path):
    parser = etree.XMLParser(remove_blank_text=True)
    tree = etree.parse(svg_path, parser)
    root = tree.getroot()

    # Find all root-level <g> elements
    root_gs = [el for el in root if el.tag.endswith('g')]

    # Find the first <g> after <defs>
    first_g = None
    for el in root:
        if el.tag.endswith('g'):
            first_g = el
            break

    # Check first <g> group
    first_ok = (
        first_g is not None and
        first_g.attrib.get('{http://www.inkscape.org/namespaces/inkscape}groupmode') == 'layer' and
        first_g.attrib.get('{http://www.inkscape.org/namespaces/inkscape}label') == 'L1' and
        first_g.attrib.get('id') == 'g1'
    )

    # Check for at least one additional root-level L1 group without id="g1"
    found_additional = False
    for g in root_gs:
        if (
            g.attrib.get('{http://www.inkscape.org/namespaces/inkscape}groupmode') == 'layer' and
            g.attrib.get('{http://www.inkscape.org/namespaces/inkscape}label') == 'L1' and
            g.attrib.get('id', None) != 'g1'
        ):
            found_additional = True
            break

    return first_ok, found_additional

def main():
    svg_files = find_svg_files(SRC_DIR)
    bad_files = []
    for svg_path in svg_files:
        first_ok, found_additional = check_svg_structure(svg_path)
        if not (first_ok and found_additional):
            bad_files.append((svg_path, first_ok, found_additional))
    if bad_files:
        print("Files with structure issues:")
        for path, first_ok, found_additional in bad_files:
            print(f"- {os.path.relpath(path, SRC_DIR)}: first_g1_ok={first_ok}, has_additional_L1={found_additional}")
    else:
        print("All SVGs match the expected group structure.")

if __name__ == "__main__":
    main()
