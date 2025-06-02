#!/usr/bin/env python3
"""
Script to generate complete domino tile SVGs with proper orientations.
This script:
1. Reads flat-arranged reference SVGs for individual numbers (0-18)
2. Combines them to create two-number domino tiles
3. Generates all four orientations (left, right, top, bottom) for each domino
4. Uses actual dot patterns from reference files instead of placeholders
"""

import os
import re
from pathlib import Path
from xml.etree import ElementTree as ET

# Define the base directory
base_dir = Path("c:/development/mexican-train")
ref_dir = base_dir / "assets" / "tiles" / "dominos-ref"
output_dir = base_dir / "assets" / "tiles" / "dominos"

# Domino dimensions
DOMINO_WIDTH = 40
DOMINO_HEIGHT = 82
HALF_HEIGHT = 41

def extract_dots_from_reference(ref_file_path):
    """Extract dot circle elements from a flat-arranged reference SVG"""
    try:
        tree = ET.parse(ref_file_path)
        root = tree.getroot()
        
        # Find all circle elements (dots)
        dots = []
        for circle in root.findall('.//{http://www.w3.org/2000/svg}circle'):
            cx = float(circle.get('cx', 0))
            cy = float(circle.get('cy', 0))
            r = float(circle.get('r', 3))
            style = circle.get('style', 'fill:#000000;stroke-width:0.264583')
            dots.append({'cx': cx, 'cy': cy, 'r': r, 'style': style})
        
        return dots
    except Exception as e:
        print(f"Error reading {ref_file_path}: {e}")
        return []

def create_domino_svg(top_num, bottom_num, orientation='left'):
    """Create a domino SVG with proper orientation"""
    
    # Load dot patterns from reference files
    top_ref_file = ref_dir / f"domino-{top_num}-flat-arranged.svg"
    bottom_ref_file = ref_dir / f"domino-{bottom_num}-flat-arranged.svg"
    
    if not top_ref_file.exists():
        print(f"Warning: Reference file not found: {top_ref_file}")
        return None
    if not bottom_ref_file.exists():
        print(f"Warning: Reference file not found: {bottom_ref_file}")
        return None
    
    top_dots = extract_dots_from_reference(top_ref_file)
    bottom_dots = extract_dots_from_reference(bottom_ref_file)
      # Create SVG structure based on orientation
    if orientation in ['top', 'bottom']:
        # Vertical layout: 40x82 (tall and narrow)
        width, height = DOMINO_WIDTH, DOMINO_HEIGHT
        viewbox = f"0 0 {width} {height}"
    else:  # left, right
        # Horizontal layout: 82x40 (wide and short)
        width, height = DOMINO_HEIGHT, DOMINO_WIDTH
        viewbox = f"0 0 {width} {height}"
    
    # Create SVG root
    svg_root = ET.Element('svg')
    svg_root.set('xmlns', 'http://www.w3.org/2000/svg')
    svg_root.set('width', str(width))
    svg_root.set('height', str(height))
    svg_root.set('viewBox', viewbox)
    svg_root.set('version', '1.1')
      # Add background rectangles (red squares for each half)
    if orientation in ['top', 'bottom']:
        # Vertical domino - two red squares stacked vertically
        top_rect = ET.SubElement(svg_root, 'rect')
        top_rect.set('style', 'fill:#ff0000;stroke-width:0.264583')
        top_rect.set('width', str(width))
        top_rect.set('height', str(height/2))
        top_rect.set('x', '0')
        top_rect.set('y', '0')
        
        bottom_rect = ET.SubElement(svg_root, 'rect')
        bottom_rect.set('style', 'fill:#ff0000;stroke-width:0.264583')
        bottom_rect.set('width', str(width))
        bottom_rect.set('height', str(height/2))
        bottom_rect.set('x', '0')
        bottom_rect.set('y', str(height/2))
    else:  # left, right
        # Horizontal domino - two red squares side by side
        left_rect = ET.SubElement(svg_root, 'rect')
        left_rect.set('style', 'fill:#ff0000;stroke-width:0.264583')
        left_rect.set('width', str(width/2))
        left_rect.set('height', str(height))
        left_rect.set('x', '0')
        left_rect.set('y', '0')
        
        right_rect = ET.SubElement(svg_root, 'rect')
        right_rect.set('style', 'fill:#ff0000;stroke-width:0.264583')
        right_rect.set('width', str(width/2))
        right_rect.set('height', str(height))
        right_rect.set('x', str(width/2))
        right_rect.set('y', '0')    # Add 2-pixel black dividing line between the two halves
    line = ET.SubElement(svg_root, 'line')
    line.set('style', 'stroke:#000000;stroke-width:2')
    
    if orientation in ['top', 'bottom']:
        # Vertical domino - horizontal dividing line at center
        line.set('x1', '0')
        line.set('y1', str(height/2))
        line.set('x2', str(width))
        line.set('y2', str(height/2))
    else:  # left, right
        # Horizontal domino - vertical dividing line at center
        line.set('x1', str(width/2))
        line.set('y1', '0')
        line.set('x2', str(width/2))
        line.set('y2', str(height))
      # Position dots based on orientation
    if orientation == 'left':
        # Horizontal domino (82x40): top number on left half, bottom number on right half
        place_dots_in_region(svg_root, top_dots, 0, 0, 41, 40)  # Left half
        place_dots_in_region(svg_root, bottom_dots, 41, 0, 41, 40)  # Right half
        
    elif orientation == 'right':
        # Horizontal domino (82x40): bottom number on left half, top number on right half (reversed)
        place_dots_in_region(svg_root, bottom_dots, 0, 0, 41, 40)  # Left half
        place_dots_in_region(svg_root, top_dots, 41, 0, 41, 40)  # Right half
        
    elif orientation == 'top':
        # Vertical domino (40x82): top number on top half, bottom number on bottom half
        place_dots_in_region(svg_root, top_dots, 0, 0, 40, 41)  # Top half
        place_dots_in_region(svg_root, bottom_dots, 0, 41, 40, 41)  # Bottom half
        
    elif orientation == 'bottom':
        # Vertical domino (40x82): bottom number on top half, top number on bottom half (reversed)
        place_dots_in_region(svg_root, bottom_dots, 0, 0, 40, 41)  # Top half
        place_dots_in_region(svg_root, top_dots, 0, 41, 40, 41)  # Bottom half
    
    return svg_root

def place_dots_in_region(svg_root, dots, region_x, region_y, region_width, region_height):
    """Place dots from a 40x40 reference into a specified region, scaling appropriately"""
    
    # The reference dots are in a 40x40 space
    ref_size = 40
    
    # Calculate scaling factors
    scale_x = region_width / ref_size
    scale_y = region_height / ref_size
    
    for dot in dots:
        # Scale and translate dot position
        new_cx = region_x + (dot['cx'] * scale_x)
        new_cy = region_y + (dot['cy'] * scale_y)
        
        # Create circle element
        circle = ET.SubElement(svg_root, 'circle')
        circle.set('cx', str(new_cx))
        circle.set('cy', str(new_cy))
        circle.set('r', str(dot['r'] * min(scale_x, scale_y)))  # Scale radius proportionally
        circle.set('style', 'fill:#000000;stroke-width:0.264583')  # Black dots on red background

def generate_all_domino_combinations():
    """Generate all valid domino combinations with all orientations"""
    
    # Ensure output directory exists
    output_dir.mkdir(parents=True, exist_ok=True)
    
    max_num = 18  # Assuming dominos go from 0 to 18
    orientations = ['left', 'right', 'top', 'bottom']
    
    generated_count = 0    # Generate all unique combinations (avoid duplicates like 5-3 and 3-5)
    # Format: domino-N-M where N >= M (larger number first)
    for smaller_num in range(max_num + 1):
        for larger_num in range(smaller_num, max_num + 1):  # larger_num >= smaller_num
            
            for orientation in orientations:
                # Create filename with larger number first
                filename = f"domino-{larger_num}-{smaller_num}_{orientation}.svg"
                output_path = output_dir / filename
                
                # Generate SVG (the function handles which number goes where based on orientation)
                svg_root = create_domino_svg(larger_num, smaller_num, orientation)
                if svg_root is not None:
                    # Write to file
                    tree = ET.ElementTree(svg_root)
                    ET.indent(tree, space="  ", level=0)  # Pretty formatting
                    tree.write(output_path, encoding='utf-8', xml_declaration=True)
                    generated_count += 1
                    
                    if generated_count % 20 == 0:
                        print(f"Generated {generated_count} domino files...")
    
    print(f"Successfully generated {generated_count} domino SVG files")

def main():
    """Main execution function"""
    
    # Verify directories exist
    if not ref_dir.exists():
        print(f"Error: Reference directory not found: {ref_dir}")
        return
    
    if not output_dir.exists():
        print(f"Creating output directory: {output_dir}")
        output_dir.mkdir(parents=True, exist_ok=True)
    
    print("=== Domino Tile Generator ===")
    print(f"Reference directory: {ref_dir}")
    print(f"Output directory: {output_dir}")
    print()
    
    # Check for required reference files
    missing_refs = []
    for i in range(19):  # 0-18
        ref_file = ref_dir / f"domino-{i}-flat-arranged.svg"
        if not ref_file.exists():
            missing_refs.append(f"domino-{i}-flat-arranged.svg")
    
    if missing_refs:
        print(f"Warning: Missing {len(missing_refs)} reference files:")
        for ref in missing_refs[:5]:  # Show first 5
            print(f"  - {ref}")
        if len(missing_refs) > 5:
            print(f"  ... and {len(missing_refs) - 5} more")
        print()
    
    confirm = input("Generate all domino tiles? [y/N]: ").strip().lower()
    if confirm != 'y':
        print("Aborted by user.")
        return
    
    generate_all_domino_combinations()
    print("\nDone!")

if __name__ == "__main__":
    main()
