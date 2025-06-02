# filepath: c:\development\mexican-train\tools\create_rotated_dominos.py
#!/usr/bin/env python3
"""
create_rotated_dominos.py
Creates rotated versions of domino SVG files by directly manipulating SVG content
"""

import os
import xml.etree.ElementTree as ET
from pathlib import Path
import hashlib

# Configuration
DOMINO_DIR = r"c:\development\mexican-train\assets\tiles\dominos"

def get_domino_files():
    """Get all base domino SVG files (excluding back, single-number, and rotated versions)"""
    domino_dir = Path(DOMINO_DIR)
    if not domino_dir.exists():
        print(f"Error: Domino directory not found: {DOMINO_DIR}")
        return []
    
    # Find all domino-*.svg files excluding back and already rotated versions
    pattern = "domino-*.svg"
    all_files = list(domino_dir.glob(pattern))
    
    # Filter out back, import files, single-number dominoes, and already rotated files
    base_files = []
    for file in all_files:
        name = file.name
        if (not name.endswith('.import') and 
            'back' not in name and 
            not any(suffix in name for suffix in ['_top', '_bottom', '_left', '_right'])):
            
            # Check if it's a two-number domino (domino-X-Y.svg pattern)
            stem = file.stem  # removes .svg extension
            if stem.startswith('domino-'):
                number_part = stem[7:]  # remove 'domino-' prefix
                # Count hyphens - should have exactly one for X-Y pattern
                if number_part.count('-') == 1:
                    base_files.append(file)
                else:
                    print(f"  Skipping single-number domino: {name}")
    
    return base_files

def create_rotated_svg(input_file, output_file, rotation_degrees, target_width, target_height):
    """Create a rotated SVG by manipulating the SVG content directly"""
    try:
        # Parse the original SVG
        tree = ET.parse(input_file)
        root = tree.getroot()
        
        # Define namespaces
        namespaces = {
            '': 'http://www.w3.org/2000/svg',
            'svg': 'http://www.w3.org/2000/svg'
        }
        
        # Update the root SVG dimensions
        root.set('width', str(target_width))
        root.set('height', str(target_height))
        
        # Calculate viewBox for the new dimensions
        # For vertical orientations (40x82), we need to adjust the viewBox
        if target_width == 40 and target_height == 82:
            # Vertical orientation - swap viewBox dimensions
            viewbox = f"0 0 10.583355 21.69582"
        else:
            # Horizontal orientation - keep original viewBox
            viewbox = f"0 0 21.69582 10.583355"
        
        root.set('viewBox', viewbox)
        
        # Find all content elements (everything except metadata)
        content_elements = []
        for child in root:
            tag_name = child.tag.split('}')[-1] if '}' in child.tag else child.tag
            if tag_name not in ['namedview', 'metadata', 'defs']:
                content_elements.append(child)
        
        # Apply rotation transform to content elements
        if rotation_degrees != 0:
            # Calculate transform origin (center of the viewBox)
            if target_width == 40 and target_height == 82:
                # Vertical orientation
                cx, cy = 5.291677, 10.847909  # Center of 10.583355 x 21.69582
            else:
                # Horizontal orientation  
                cx, cy = 10.847909, 5.291677  # Center of 21.69582 x 10.583355
            
            transform = f"rotate({rotation_degrees} {cx} {cy})"
            
            # Create a group element to hold all content with the transform
            group = ET.Element('g')
            group.set('transform', transform)
            
            # Move all content elements into the group
            for element in content_elements:
                root.remove(element)
                group.append(element)
            
            # Add the group back to the root
            root.append(group)
        
        # Write the modified SVG
        tree.write(output_file, encoding='utf-8', xml_declaration=True)
        
        return True
        
    except Exception as e:
        print(f"    ✗ Error creating rotated SVG: {e}")
        return False

def create_godot_import_file(svg_file):
    """Create a .import file for Godot"""
    import_file = f"{svg_file}.import"
    
    # Generate a simple UID (not cryptographically secure, but sufficient for Godot)
    uid = hashlib.md5(svg_file.encode()).hexdigest()[:16]
    
    import_content = f"""[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://{uid}"
path="res://.godot/imported/{os.path.basename(svg_file)}-{uid}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="res://assets/tiles/dominos/{os.path.basename(svg_file)}"
dest_files=["res://.godot/imported/{os.path.basename(svg_file)}-{uid}.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
svg/scale=1.0
editor/scale_with_editor_scale=false
editor/convert_colors_with_editor_theme=false
"""
    
    try:
        with open(import_file, 'w', encoding='utf-8') as f:
            f.write(import_content)
        return True
    except Exception as e:
        print(f"    ✗ Failed to create import file: {e}")
        return False

def main():
    print("Starting domino rotation generation with direct SVG manipulation...")
    print(f"Domino Directory: {DOMINO_DIR}")
    
    # Get domino files
    domino_files = get_domino_files()
    if not domino_files:
        print("No domino files found to process")
        return 1
    
    print(f"Found {len(domino_files)} domino files to process")
    
    # Define rotations: suffix, degrees, description, target_width, target_height
    # Base domino is 82x40 (horizontal)
    # For vertical orientations, we want 40x82
    rotations = [
        ("_left", 0, "Left (0°)", 82, 40),        # Horizontal - no rotation
        ("_right", 180, "Right (180°)", 82, 40),  # Horizontal - 180° rotation
        ("_top", 90, "Top (90°)", 40, 82),        # Vertical - 90° rotation  
        ("_bottom", 270, "Bottom (270°)", 40, 82) # Vertical - 270° rotation
    ]
    
    processed = 0
    failed = 0
    
    for domino_file in domino_files:
        print(f"Processing: {domino_file.name}")
        
        for suffix, degrees, description, target_width, target_height in rotations:
            base_name = domino_file.stem  # filename without extension
            output_file = domino_file.parent / f"{base_name}{suffix}.svg"
            
            # Skip if already exists
            if output_file.exists():
                print(f"  Skipping {description} - already exists")
                continue
            
            print(f"  Creating {description} ({target_width}x{target_height})...")
            
            if create_rotated_svg(domino_file, output_file, degrees, target_width, target_height):
                print(f"    ✓ Created: {output_file.name}")
                # Create Godot import file
                if create_godot_import_file(str(output_file)):
                    print("    ✓ Created import file")
                
                processed += 1
            else:
                failed += 1
    
    print()
    print("Rotation generation complete!")
    print(f"Successfully created: {processed} files")
    if failed > 0:
        print(f"Failed to create: {failed} files")
    
    print()
    print("Note: You may need to refresh the Godot FileSystem dock to see the new files.")
    return 0

if __name__ == "__main__":
    import sys
    sys.exit(main())
