#!/usr/bin/env python3
"""
Script to generate experimental domino template SVGs for shader-based coloring.
Creates templates with all dot positions filled with white dots that can be
dynamically recolored by the shader.
"""

import os
from pathlib import Path

# Define directories
base_dir = Path("c:/development/mexican-train")
output_dir = base_dir / "assets" / "experimental"

# Ensure output directory exists
output_dir.mkdir(parents=True, exist_ok=True)

# Domino dimensions
DOMINO_WIDTH_HORIZONTAL = 82
DOMINO_HEIGHT_HORIZONTAL = 40
DOMINO_WIDTH_VERTICAL = 40
DOMINO_HEIGHT_VERTICAL = 82

# Dot patterns for each number (positions within a 40x40 square)
# Using standard domino dot arrangements
DOT_PATTERNS = {
    0: [],  # No dots
    1: [(20, 20)],  # Center
    2: [(10, 10), (30, 30)],  # Diagonal
    3: [(10, 10), (20, 20), (30, 30)],  # Diagonal line
    4: [(10, 10), (30, 10), (10, 30), (30, 30)],  # Four corners
    5: [(10, 10), (30, 10), (20, 20), (10, 30), (30, 30)],  # Four corners + center
    6: [(10, 8), (30, 8), (10, 20), (30, 20), (10, 32), (30, 32)],  # Two columns
    7: [(10, 8), (30, 8), (10, 20), (20, 20), (30, 20), (10, 32), (30, 32)],  # Two columns + center
    8: [(10, 6), (30, 6), (10, 16), (30, 16), (10, 24), (30, 24), (10, 34), (30, 34)],  # Two columns, 4 each
    9: [(8, 6), (20, 6), (32, 6), (8, 20), (20, 20), (32, 20), (8, 34), (20, 34), (32, 34)],  # Three columns, 3 each
    10: [(8, 5), (20, 5), (32, 5), (8, 15), (20, 15), (32, 15), (8, 25), (20, 25), (32, 25), (20, 35)],  # 3x3 + bottom center
    11: [(8, 4), (20, 4), (32, 4), (8, 14), (20, 14), (32, 14), (8, 24), (20, 24), (32, 24), (14, 34), (26, 34)],  # 3x3 + 2 bottom
    12: [(8, 4), (20, 4), (32, 4), (8, 14), (20, 14), (32, 14), (8, 24), (20, 24), (32, 24), (8, 34), (20, 34), (32, 34)],  # 3x4 grid
    13: [(6, 4), (18, 4), (30, 4), (6, 13), (18, 13), (30, 13), (6, 22), (18, 22), (30, 22), (12, 31), (24, 31), (6, 31), (30, 31)],  # 3x3 + 4 bottom
    14: [(6, 3), (18, 3), (30, 3), (6, 12), (18, 12), (30, 12), (6, 21), (18, 21), (30, 21), (6, 30), (18, 30), (30, 30), (12, 37), (24, 37)],  # 3x4 + 2 extra
    15: [(6, 3), (18, 3), (30, 3), (6, 11), (18, 11), (30, 11), (6, 19), (18, 19), (30, 19), (6, 27), (18, 27), (30, 27), (6, 35), (18, 35), (30, 35)],  # 3x5
    16: [(5, 3), (15, 3), (25, 3), (35, 3), (5, 11), (15, 11), (25, 11), (35, 11), (5, 19), (15, 19), (25, 19), (35, 19), (5, 27), (15, 27), (25, 27), (35, 27)],  # 4x4
    17: [(5, 3), (15, 3), (25, 3), (35, 3), (5, 11), (15, 11), (25, 11), (35, 11), (5, 19), (15, 19), (25, 19), (35, 19), (5, 27), (15, 27), (25, 27), (35, 27), (20, 35)],  # 4x4 + center bottom
    18: [(5, 2), (15, 2), (25, 2), (35, 2), (5, 10), (15, 10), (25, 10), (35, 10), (5, 18), (15, 18), (25, 18), (35, 18), (5, 26), (15, 26), (25, 26), (35, 26), (10, 34), (30, 34)],  # 4x4 + 2 bottom
}

def create_template_svg(orientation='horizontal'):
    """Create a template SVG with all possible dot positions filled with white dots"""
    
    if orientation == 'horizontal':
        width, height = DOMINO_WIDTH_HORIZONTAL, DOMINO_HEIGHT_HORIZONTAL
        # For horizontal: left half and right half
        half_width = width // 2
        left_region = (0, 0, half_width, height)
        right_region = (half_width, 0, half_width, height)
        divider_line = f'<line style="stroke:#000000;stroke-width:2" x1="{half_width}" y1="0" x2="{half_width}" y2="{height}" />'
    else:  # vertical
        width, height = DOMINO_WIDTH_VERTICAL, DOMINO_HEIGHT_VERTICAL
        # For vertical: top half and bottom half
        half_height = height // 2
        left_region = (0, 0, width, half_height)  # Top region
        right_region = (0, half_height, width, half_height)  # Bottom region
        divider_line = f'<line style="stroke:#000000;stroke-width:2" x1="0" y1="{half_height}" x2="{width}" y2="{half_height}" />'
    
    # Start SVG
    svg_lines = [
        '<?xml version="1.0" encoding="utf-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" version="1.1">',
        f'  <rect style="fill:#ff0000;stroke-width:0.264583" width="{left_region[2]}" height="{left_region[3]}" x="{left_region[0]}" y="{left_region[1]}" />',
        f'  <rect style="fill:#ff0000;stroke-width:0.264583" width="{right_region[2]}" height="{right_region[3]}" x="{right_region[0]}" y="{right_region[1]}" />',
        f'  {divider_line}',
    ]
    
    # Add all possible dots as white circles (shader will recolor them)
    # Use the maximum dot pattern (18 dots) for each half
    max_dots = DOT_PATTERNS[18]
    
    # Add dots to left/top half
    for dot_x, dot_y in max_dots:
        if orientation == 'horizontal':
            # Scale dot position to left half
            scaled_x = (dot_x * left_region[2]) / 40.0
            scaled_y = (dot_y * left_region[3]) / 40.0
            actual_x = left_region[0] + scaled_x
            actual_y = left_region[1] + scaled_y
        else:  # vertical
            # Scale dot position to top half
            scaled_x = (dot_x * left_region[2]) / 40.0
            scaled_y = (dot_y * left_region[3]) / 40.0
            actual_x = left_region[0] + scaled_x
            actual_y = left_region[1] + scaled_y
        
        svg_lines.append(f'  <circle style="fill:#ffffff;stroke-width:0" cx="{actual_x:.1f}" cy="{actual_y:.1f}" r="2" />')
    
    # Add dots to right/bottom half
    for dot_x, dot_y in max_dots:
        if orientation == 'horizontal':
            # Scale dot position to right half
            scaled_x = (dot_x * right_region[2]) / 40.0
            scaled_y = (dot_y * right_region[3]) / 40.0
            actual_x = right_region[0] + scaled_x
            actual_y = right_region[1] + scaled_y
        else:  # vertical
            # Scale dot position to bottom half
            scaled_x = (dot_x * right_region[2]) / 40.0
            scaled_y = (dot_y * right_region[3]) / 40.0
            actual_x = right_region[0] + scaled_x
            actual_y = right_region[1] + scaled_y
        
        svg_lines.append(f'  <circle style="fill:#ffffff;stroke-width:0" cx="{actual_x:.1f}" cy="{actual_y:.1f}" r="2" />')
    
    # Close SVG
    svg_lines.append('</svg>')
    
    return '\n'.join(svg_lines)

def main():
    """Generate template SVGs for experimental shader-based dominoes"""
    
    print("Generating experimental domino template SVGs...")
    
    # Generate horizontal template
    horizontal_svg = create_template_svg('horizontal')
    horizontal_path = output_dir / "domino_template_left.svg"
    with open(horizontal_path, 'w', encoding='utf-8') as f:
        f.write(horizontal_svg)
    print(f"Created: {horizontal_path}")
    
    # Generate vertical template  
    vertical_svg = create_template_svg('vertical')
    vertical_path = output_dir / "domino_template_top.svg"
    with open(vertical_path, 'w', encoding='utf-8') as f:
        f.write(vertical_svg)
    print(f"Created: {vertical_path}")
    
    print("Template SVGs generated successfully!")

if __name__ == "__main__":
    main()
