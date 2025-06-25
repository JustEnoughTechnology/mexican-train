#!/usr/bin/env python3
"""
Generate all 364 BaseDomino scenes for Mexican Train dominoes game.
Creates 91 domino combinations (0-0 through 12-12) × 4 orientations each.
"""

import os
import hashlib

def generate_uid(content):
    """Generate a unique UID for a scene based on its content."""
    hash_object = hashlib.md5(content.encode())
    hash_hex = hash_object.hexdigest()
    # Convert to Godot UID format (base62-like)
    return f"uid://b{hash_hex[:10]}"

def create_horizontal_scene(largest, smallest, orientation_side, base_dir):
    """Create a horizontal domino scene (left or right orientation)."""
    
    # Determine file naming and texture order
    if orientation_side == "left":
        filename = f"base_domino_{largest}_{smallest}_horizontal_left.tscn"
        orientation_vector = "Vector2i(0, 0)"
        first_texture_id = "2"
        second_texture_id = "3"
        first_texture_path = f"res://assets/dominos/half/half-{largest}.svg"
        second_texture_path = f"res://assets/dominos/half/half-{smallest}.svg"
    else:  # right
        filename = f"base_domino_{largest}_{smallest}_horizontal_right.tscn"
        orientation_vector = "Vector2i(0, 1)"
        first_texture_id = "2"
        second_texture_id = "3"
        first_texture_path = f"res://assets/dominos/half/half-{smallest}.svg"
        second_texture_path = f"res://assets/dominos/half/half-{largest}.svg"
    
    uid = generate_uid(f"{largest}_{smallest}_h_{orientation_side}")
    
    content = f"""[gd_scene load_steps=4 format=3 uid="{uid}"]

[ext_resource type="Script" path="res://scripts/dominos/base_domino.gd" id="1"]
[ext_resource type="Texture2D" path="{first_texture_path}" id="2"]
[ext_resource type="Texture2D" path="{second_texture_path}" id="3"]

[node name="BaseDomino" type="Control"]
layout_mode = 3
anchors_preset = 0
custom_minimum_size = Vector2(81, 40)
script = ExtResource("1")
largest_value = {largest}
smallest_value = {smallest}
orientation = {orientation_vector}

[node name="DominoVisual" type="HBoxContainer" parent="."]
layout_mode = 2
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 0

[node name="LargestHalf" type="TextureRect" parent="DominoVisual"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
texture = ExtResource("{first_texture_id}")
expand_mode = 1
stretch_mode = 5

[node name="Separator" type="ColorRect" parent="DominoVisual"]
custom_minimum_size = Vector2(1, 40)
layout_mode = 2
color = Color(0, 0, 0, 1)

[node name="SmallestHalf" type="TextureRect" parent="DominoVisual"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
texture = ExtResource("{second_texture_id}")
expand_mode = 1
stretch_mode = 5
"""
    
    filepath = os.path.join(base_dir, filename)
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)
    
    return filepath

def create_vertical_scene(largest, smallest, orientation_side, base_dir):
    """Create a vertical domino scene (top or bottom orientation)."""
    
    # Determine file naming and texture order
    if orientation_side == "top":
        filename = f"base_domino_{largest}_{smallest}_vertical_top.tscn"
        orientation_vector = "Vector2i(1, 0)"
        first_texture_id = "2"
        second_texture_id = "3"
        first_texture_path = f"res://assets/dominos/half/half-{largest}.svg"
        second_texture_path = f"res://assets/dominos/half/half-{smallest}.svg"
    else:  # bottom
        filename = f"base_domino_{largest}_{smallest}_vertical_bottom.tscn"
        orientation_vector = "Vector2i(1, 1)"
        first_texture_id = "2"
        second_texture_id = "3"
        first_texture_path = f"res://assets/dominos/half/half-{smallest}.svg"
        second_texture_path = f"res://assets/dominos/half/half-{largest}.svg"
    
    uid = generate_uid(f"{largest}_{smallest}_v_{orientation_side}")
    
    content = f"""[gd_scene load_steps=4 format=3 uid="{uid}"]

[ext_resource type="Script" path="res://scripts/dominos/base_domino.gd" id="1"]
[ext_resource type="Texture2D" path="{first_texture_path}" id="2"]
[ext_resource type="Texture2D" path="{second_texture_path}" id="3"]

[node name="BaseDomino" type="Control"]
custom_minimum_size = Vector2(40, 81)
layout_mode = 3
anchors_preset = 0
script = ExtResource("1")
largest_value = {largest}
smallest_value = {smallest}
orientation = {orientation_vector}

[node name="DominoVisual" type="VBoxContainer" parent="."]
layout_mode = 2
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 0

[node name="LargestHalf" type="TextureRect" parent="DominoVisual"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
texture = ExtResource("{first_texture_id}")
expand_mode = 1
stretch_mode = 5

[node name="Separator" type="ColorRect" parent="DominoVisual"]
custom_minimum_size = Vector2(40, 1)
layout_mode = 2
color = Color(0, 0, 0, 1)

[node name="SmallestHalf" type="TextureRect" parent="DominoVisual"]
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
texture = ExtResource("{second_texture_id}")
expand_mode = 1
stretch_mode = 5
"""
    
    filepath = os.path.join(base_dir, filename)
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)
    
    return filepath

def main():
    """Generate all BaseDomino scenes for the double-12 domino set."""
    
    # Base directory for domino scenes
    base_dir = "scenes/dominos/base_dominos"
    
    # Ensure directory exists
    os.makedirs(base_dir, exist_ok=True)
    
    total_scenes = 0
    created_files = []
    
    print("Generating all BaseDomino scenes for double-12 domino set...")
    print("=" * 60)
    
    # Generate all domino combinations (0-0 through 12-12)
    for largest in range(13):  # 0 to 12
        for smallest in range(largest + 1):  # 0 to largest (to avoid duplicates)
            domino_name = f"{largest}-{smallest}"
            print(f"Creating scenes for domino {domino_name}...")
            
            # Create all 4 orientations for this domino
            orientations = [
                ("horizontal", "left"),
                ("horizontal", "right"), 
                ("vertical", "top"),
                ("vertical", "bottom")
            ]
            
            for direction, side in orientations:
                if direction == "horizontal":
                    filepath = create_horizontal_scene(largest, smallest, side, base_dir)
                else:  # vertical
                    filepath = create_vertical_scene(largest, smallest, side, base_dir)
                
                created_files.append(filepath)
                total_scenes += 1
                print(f"  ✓ Created {os.path.basename(filepath)}")
    
    print("=" * 60)
    print(f"Successfully created {total_scenes} BaseDomino scenes!")
    print(f"Expected: 364 scenes (91 dominoes × 4 orientations)")
    print(f"Created: {total_scenes} scenes")
    
    if total_scenes == 364:
        print("✅ All scenes generated successfully!")
    else:
        print(f"⚠️  Mismatch in expected scene count!")
    
    print(f"\nScenes saved to: {base_dir}/")
    print("\nFirst few created files:")
    for filepath in created_files[:10]:
        print(f"  - {os.path.basename(filepath)}")
    
    if len(created_files) > 10:
        print(f"  ... and {len(created_files) - 10} more files")

if __name__ == "__main__":
    main()

