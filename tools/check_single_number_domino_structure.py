import os
import re
from lxml import etree

SRC_DIR = os.path.join("assets", "tiles", "dominos-ref")

def find_single_number_svgs(root_dir):
    svg_files = []
    pattern = re.compile(r"domino-\d+\.svg$")
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if pattern.match(filename):
                svg_files.append(os.path.join(dirpath, filename))
    return svg_files

def get_g_structure(svg_path):
    parser = etree.XMLParser(remove_blank_text=True)
    tree = etree.parse(svg_path, parser)
    root = tree.getroot()
    # Collect a tuple of (label, id) for each root-level <g>
    structure = []
    for el in root:
        if el.tag.endswith('g'):
            label = el.attrib.get('{http://www.inkscape.org/namespaces/inkscape}label')
            gid = el.attrib.get('id')
            structure.append((label, gid))
    return structure

def main():
    svg_files = find_single_number_svgs(SRC_DIR)
    structures = {}
    for svg_path in svg_files:
        structure = get_g_structure(svg_path)
        structures[svg_path] = structure

    # Use the structure of the first file as reference
    ref_file, ref_structure = next(iter(structures.items()))
    mismatches = []
    for path, struct in structures.items():
        if struct != ref_structure:
            mismatches.append((path, struct))

    print(f"Reference structure from {os.path.basename(ref_file)}: {ref_structure}")
    if mismatches:
        print("Files with differing structure:")
        for path, struct in mismatches:
            print(f"- {os.path.basename(path)}: {struct}")
    else:
        print("All domino-N.svg files have the same root-level <g> structure.")

if __name__ == "__main__":
    main()
