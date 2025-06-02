#!/usr/bin/env python3
"""
Script to create pre-rotated domino SVG files.
This creates rotated versions of all domino SVGs for each orientation.
"""

import os
import re
from pathlib import Path
from xml.etree import ElementTree as ET

# Define the base directory
base_dir = Path("c:/development/mexican-train")
assets_dir = base_dir / "assets" / "tiles" / "dominos"

# Orientation suffixes
orientations = {
    "largest_left": "",  # Original orientation - no suffix
    "largest_right": "_right",
    "largest_top": "_top", 
    "largest_bottom": "_bottom"
}

# Rotation angles for each orientation (clockwise from original)
rotations = {
    "largest_left": 0,
    "largest_right": 180,
    "largest_top": 90,
    "largest_bottom": 270
}

def get_svg_dimensions(svg_content):
    """Extract width and height from SVG content"""
    # Parse width and height from the svg tag
    width_match = re.search(r'width="([^"]*)"', svg_content)
    height_match = re.search(r'height="([^"]*)"', svg_content)
    
    if width_match and height_match:
        return float(width_match.group(1)), float(height_match.group(1))
    return None, None

def create_rotated_svg(original_svg_path, rotation_angle, output_path):
    """Create a rotated version of an SVG file"""
    
    with open(original_svg_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Get original dimensions
    width, height = get_svg_dimensions(content)
    if width is None or height is None:
        print(f"Could not extract dimensions from {original_svg_path}")
        return False
    
    # For 90/270 degree rotations, swap width and height
    if rotation_angle in [90, 270]:
        new_width, new_height = height, width
    else:
        new_width, new_height = width, height
    
    # Parse the SVG
    try:
        # Remove XML declaration if present to avoid issues
        if content.startswith('<?xml'):
            content = content.split('>', 1)[1]
        
        # Parse the SVG content
        root = ET.fromstring(content)
        
        # Update dimensions
        root.set('width', str(new_width))
        root.set('height', str(new_height))
        
        # Update viewBox if it exists
        viewbox = root.get('viewBox')
        if viewbox:
            vb_parts = viewbox.split()
            if len(vb_parts) == 4:
                if rotation_angle in [90, 270]:
                    # Swap width and height in viewBox
                    root.set('viewBox', f"{vb_parts[0]} {vb_parts[1]} {vb_parts[3]} {vb_parts[2]}")
        
        # Calculate center point for rotation
        center_x = width / 2
        center_y = height / 2
        
        # Create transform group for rotation
        if rotation_angle != 0:
            # Find the main content (skip defs, namedview, etc.)
            content_elements = []
            for child in root:
                tag_name = child.tag.split('}')[-1] if '}' in child.tag else child.tag
                if tag_name not in ['defs', 'namedview', 'metadata']:
                    content_elements.append(child)
            
            # Remove content elements from root
            for elem in content_elements:
                root.remove(elem)
            
            # Create transform group
            g = ET.SubElement(root, 'g')
            
            # Set transform based on rotation
            if rotation_angle == 90:
                transform = f"rotate(90 {center_x} {center_y}) translate({(height-width)/2} {(width-height)/2})"
            elif rotation_angle == 180:
                transform = f"rotate(180 {center_x} {center_y})"
            elif rotation_angle == 270:
                transform = f"rotate(270 {center_x} {center_y}) translate({(height-width)/2} {(width-height)/2})"
            
            g.set('transform', transform)
            
            # Add content elements to transform group
            for elem in content_elements:
                g.append(elem)
        
        # Write the rotated SVG
        ET.register_namespace('', 'http://www.w3.org/2000/svg')
        ET.register_namespace('inkscape', 'http://www.inkscape.org/namespaces/inkscape')
        ET.register_namespace('sodipodi', 'http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd')
        
        tree = ET.ElementTree(root)
        tree.write(output_path, encoding='utf-8', xml_declaration=True)
        
        return True
        
    except Exception as e:
        print(f"Error processing {original_svg_path}: {e}")
        return False

def main():
    """Generate rotated versions of all domino SVGs"""
    
    if not assets_dir.exists():
        print(f"Assets directory not found: {assets_dir}")
        return

    # Print source and destination directories and prompt for confirmation

    # Set correct source and destination directories
    source_dir = base_dir / "assets" / "tiles" / "dominos-ref"
    dest_dir = assets_dir
    print("Source directory for base domino SVGs:   ", str(source_dir.resolve()))
    print("Destination directory for output SVGs:   ", str(dest_dir.resolve()))
    confirm = input("Proceed with these paths? [y/N]: ").strip().lower()
    if confirm != 'y':
        print("Aborted by user.")
        return

    # Only use two-number domino SVGs (e.g., domino-6-5.svg)
    import re
    domino_files = []
    two_number_pattern = re.compile(r"domino-(\d+)-(\d+)\.svg$")
    for svg_file in source_dir.glob("domino-*.svg"):
        filename = svg_file.name
        if two_number_pattern.match(filename):
            domino_files.append(svg_file)

    print(f"Found {len(domino_files)} two-number domino files in source directory")

    # Create rotated versions in the destination directory
    for svg_file in domino_files:
        base_name = svg_file.stem  # filename without extension

        for orientation, suffix in orientations.items():
            # Always create all four orientations, including 'largest_left' (the base orientation)
            if orientation == "largest_left":
                # For left, always create domino-*-left.svg (not just domino-*.svg)
                output_name = f"{base_name}_left.svg"
            else:
                output_name = f"{base_name}{suffix}.svg"
            output_path = dest_dir / output_name
            rotation = rotations[orientation]

            print(f"Creating {output_name} (rotation: {rotation}°)")

            success = create_rotated_svg(svg_file, rotation, output_path)
            if not success:
                print(f"Failed to create {output_name}")

if __name__ == "__main__":
    main()
