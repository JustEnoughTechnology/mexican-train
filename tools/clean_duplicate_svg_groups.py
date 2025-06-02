import os
import xml.etree.ElementTree as ET

SRC_DIR = os.path.join("assets", "tiles", "dominos-ref")
DST_DIR = os.path.join("assets", "tiles", "dominos")

def find_svg_files(root_dir):
    svg_files = []
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.lower().endswith('.svg'):
                svg_files.append(os.path.join(dirpath, filename))
    return svg_files

def remove_duplicate_g_elements(tree):
    root = tree.getroot()
    ns = {'svg': 'http://www.w3.org/2000/svg'}
    all_gs = root.findall('.//svg:g', ns)
    seen = set()
    removed = 0
    for g in all_gs:
        g_str = ET.tostring(g, encoding='utf-8')
        if g_str in seen:
            parent = g.getparent() if hasattr(g, 'getparent') else None
            if parent is not None:
                parent.remove(g)
                removed += 1
        else:
            seen.add(g_str)
    return removed

def ensure_dst_dir(dst_path):
    os.makedirs(os.path.dirname(dst_path), exist_ok=True)

def main():
    src_svgs = find_svg_files(SRC_DIR)
    total_removed = 0
    for src_path in src_svgs:
        try:
            tree = ET.parse(src_path)
            removed = remove_duplicate_g_elements(tree)
            rel_path = os.path.relpath(src_path, SRC_DIR)
            dst_path = os.path.join(DST_DIR, rel_path)
            ensure_dst_dir(dst_path)
            tree.write(dst_path, encoding='utf-8', xml_declaration=True)
            if removed > 0:
                print(f"Cleaned {removed} duplicate <g> group(s) in {rel_path}")
                total_removed += removed
            else:
                print(f"Copied (no duplicates) {rel_path}")
        except Exception as e:
            print(f"Error processing {src_path}: {e}")
    print(f"Done. Total duplicate <g> groups removed: {total_removed}")

if __name__ == "__main__":
    main()