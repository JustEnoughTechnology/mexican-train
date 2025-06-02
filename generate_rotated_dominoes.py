#!/usr/bin/env python3
"""
Script to generate rotated domino SVG files for Mexican Train game.
Creates pre-rotated versions for each orientation to eliminate programmatic rotation issues.

This script uses Inkscape command line to rotate SVG files.
Requires Inkscape to be installed and available in PATH.

Orientations:
- _left: 0 degrees (original, largest pips on left)
- _right: 180 degrees (largest pips on right)  
- _top: 90 degrees clockwise (largest pips on top)
- _bottom: 270 degrees clockwise / -90 degrees (largest pips on bottom)
"""

import os
import subprocess
import sys
from pathlib import Path

def check_inkscape():
    """Check if Inkscape is available in PATH."""
    try:
        result = subprocess.run(['inkscape', '--version'], 
                              capture_output=True, text=True, check=True)
        print(f"Found Inkscape: {result.stdout.strip()}")
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("ERROR: Inkscape not found in PATH")
        print("Please install Inkscape and ensure it's in your PATH")
        return False

def rotate_svg(input_file, output_file, rotation_degrees):
    """Rotate an SVG file using Inkscape command line."""
    try:
        # Use Inkscape to rotate the SVG
        cmd = [
            'inkscape',
            '--export-type=svg',
            f'--export-filename={output_file}',
            '--actions=select-all;transform-rotate:{};export-do'.format(rotation_degrees),
            str(input_file)
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        if result.returncode == 0:
            print(f"  ✓ Created {output_file}")
            return True
        else:
            print(f"  ✗ Failed to create {output_file}: {result.stderr}")
            return False
            
    except subprocess.CalledProcessError as e:
        print(f"  ✗ Inkscape error for {output_file}: {e.stderr}")
        return False
    except Exception as e:
        print(f"  ✗ Unexpected error for {output_file}: {e}")
        return False

def generate_rotated_dominoes():
    """Generate all rotated domino SVG files."""
    
    # Check if Inkscape is available
    if not check_inkscape():
        return False
    
    # Define paths
    dominos_dir = Path("c:/development/mexican-train/assets/tiles/dominos")
    
    if not dominos_dir.exists():
        print(f"ERROR: Dominos directory not found: {dominos_dir}")
        return False
    
    # Find all domino SVG files (excluding already rotated ones)
    domino_files = []
    for svg_file in dominos_dir.glob("domino-*.svg"):
        # Skip files that already have orientation suffixes
        if not any(suffix in svg_file.name for suffix in ['_left', '_right', '_top', '_bottom']):
            domino_files.append(svg_file)
    
    print(f"Found {len(domino_files)} domino SVG files to process")
    
    # Rotation mappings (degrees clockwise)
    rotations = {
        '_left': 0,      # Original orientation (largest pips on left)
        '_right': 180,   # Largest pips on right
        '_top': 90,      # Largest pips on top  
        '_bottom': 270   # Largest pips on bottom (same as -90)
    }
    
    success_count = 0
    total_files = len(domino_files) * len(rotations)
    
    for svg_file in domino_files:
        print(f"Processing {svg_file.name}...")
        
        # Get base name without extension
        base_name = svg_file.stem
        
        for suffix, rotation in rotations.items():
            # Create output filename
            output_name = f"{base_name}{suffix}.svg"
            output_path = dominos_dir / output_name
            
            if suffix == '_left' and rotation == 0:
                # For _left (0 degrees), just copy the original file
                try:
                    import shutil
                    shutil.copy2(svg_file, output_path)
                    print(f"  ✓ Copied {output_name}")
                    success_count += 1
                except Exception as e:
                    print(f"  ✗ Failed to copy {output_name}: {e}")
            else:
                # For other orientations, rotate using Inkscape
                if rotate_svg(svg_file, output_path, rotation):
                    success_count += 1
    
    print(f"\nCompleted: {success_count}/{total_files} files processed successfully")
    
    if success_count == total_files:
        print("✓ All domino rotations generated successfully!")
        return True
    else:
        print(f"✗ {total_files - success_count} files failed to process")
        return False

def main():
    """Main entry point."""
    print("Mexican Train Domino Rotation Generator")
    print("=" * 50)
    
    try:
        success = generate_rotated_dominoes()
        if success:
            print("\nNext steps:")
            print("1. Update domino.gd to use pre-rotated SVG files")
            print("2. Test the new orientation system")
            print("3. Remove rotation_degrees code from domino logic")
        else:
            print("\nSome files failed to process. Check errors above.")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\n\nOperation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\nUnexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
