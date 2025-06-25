#!/usr/bin/env python3
"""
Generate all 364 BaseDomino scenes for Mexican Train dominos game.
Creates scenes for all 91 domino combinations (0-0 through 12-12) in 4 orientations each.
"""

import os
from pathlib import Path

def generate_uid(largest, smallest, orientation_x, orientation_y):
    """Generate a unique UID for each domino scene."""
    return f"uid://bd_{largest}_{smallest}_{orientation_x}_{orientation_y}"

def get_orientation_info(orientation_x, orientation_y):
    """Get orientation string and container info."""
    if orientation_x == 0:  # Horizontal
        container = "HBoxContainer"
        if orientation_y == 0:  # Left
            name_suffix = "horizontal_left"
            size = "Vector2(81, 40)"
            sep_size = "Vector2(1, 40)"
            largest_first = True
        else:  # Right
            name_suffix = "horizontal_right"
            size = "Vector2(81, 40)"
            sep_size = "Vector2(1, 40)"
            largest_first = False
    else:  # Vertical
        container = "VBoxContainer"
        if orientation_y == 0:  # Top
            name_suffix = "vertical_top"
            size = "Vector2(40, 81)"
            sep_size = "Vector2(40, 1)"
            largest_first = True
        else:  # Bottom
            name_suffix = "vertical_bottom"
            size = "Vector2(40, 81)"
            sep_size = "Vector2(40, 1)"
            largest_first = False
    
    return container, name_suffix, size, sep_size, largest_first

def generate_domino_scene(largest, smallest, orientation_x, orientation_y):
    """Generate a single domino scene file content."""
    uid = generate_uid(largest, smallest, orientation_x, orientation_y)
    container, name_suffix, size, sep_size, largest_first = get_orientation_info(orientation_x, orientation_y)
    
    # Determine which texture goes where based on orientation
    if largest_first:
        first_texture = f"res://assets/dominos/half/half-{largest}.svg"
        second_texture = f"res://assets/dominos/half/half-{smallest}.svg"
        first_id = "2"
        second_id = "3"
    else:
        first_texture = f"res://assets/dominos/half/half-{smallest}.svg"
        second_texture = f"res://assets/dominos/half/half-{largest}.svg"
        first_id = "3"
        second_id = "2"
    
    scene_content = f"""[gd_scene load_steps=4 format=3 uid="{uid}"]

[ext_resource type="Script" path="res://scripts/dominos/base_domino.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/dominos/half/half-{largest}.svg" id="2"]
[ext_resource type="Texture2D" path="res://assets/dominos/half/half-{smallest}.svg" id="3"]

[node name="BaseDomino" type="Control"]
layout_mode = 3
anchors_preset = 0
custom_minimum_size = {size}
script = ExtResource("1")
largest_value = {largest}
smallest_value = {smallest}
orientation = Vector2i({orientation_x}, {orientation_y})

[node name="DominoVisual" type="{container}" parent="."]
layout_mode = 2
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 0

[node name="LargestHalf" type="TextureRect" parent="DominoVisual"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
texture = ExtResource("{first_id}")
expand_mode = 1
stretch_mode = 5

[node name="Separator" type="ColorRect" parent="DominoVisual"]
custom_minimum_size = {sep_size}
layout_mode = 2
color = Color(0, 0, 0, 1)

[node name="SmallestHalf" type="TextureRect" parent="DominoVisual"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
texture = ExtResource("{second_id}")
expand_mode = 1
stretch_mode = 5
"""
    
    return scene_content, name_suffix

def main():
    """Generate all 364 domino scenes."""
    # Base directory for scenes
    base_dir = Path("scenes/dominos/base_dominos")
    base_dir.mkdir(parents=True, exist_ok=True)
    
    total_scenes = 0
    
    print("Generating BaseDomino scenes...")
    print("=" * 50)
    
    # Generate all domino combinations (0-0 through 12-12)
    for largest in range(13):  # 0 to 12
        for smallest in range(largest + 1):  # 0 to largest (inclusive)
            print(f"Generating domino {largest}-{smallest}...")
            
            # Generate all 4 orientations for each domino
            for orientation_x in [0, 1]:  # Horizontal=0, Vertical=1
                for orientation_y in [0, 1]:  # Left/Top=0, Right/Bottom=1
                    scene_content, name_suffix = generate_domino_scene(
                        largest, smallest, orientation_x, orientation_y
                    )
                    
                    # Create filename
                    filename = f"base_domino_{largest}_{smallest}_{name_suffix}.tscn"
                    filepath = base_dir / filename
                    
                    # Write scene file
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(scene_content)
                    
                    total_scenes += 1
    
    print("=" * 50)
    print(f"Successfully generated {total_scenes} BaseDomino scenes!")
    print(f"Expected: 364 scenes (91 dominos × 4 orientations)")
    print(f"Files saved to: {base_dir.absolute()}")
    
    # Verify the count
    actual_files = len(list(base_dir.glob("*.tscn")))
    print(f"Actual files created: {actual_files}")
    
    if actual_files == 364:
        print("✅ All scenes generated successfully!")
    else:
        print(f"⚠️  Expected 364 files, but found {actual_files}")

if __name__ == "__main__":
    main()
