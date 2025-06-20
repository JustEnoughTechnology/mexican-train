#!/usr/bin/env python3
"""
Script to create experimental shader-based domino system.
This creates white-dot versions of existing SVG files and generates 
experimental domino scenes that use shaders for dot coloring.
"""

import os
import re
from pathlib import Path

def convert_svg_to_white_dots(svg_content):
    """Convert SVG content to have white dots instead of black ones."""
    # Replace black dot fills with white
    # Look for circle elements with black fill
    pattern = r'<circle([^>]*?)style="fill:#000000([^"]*)"([^>]*?)>'
    replacement = r'<circle\1style="fill:#ffffff\2"\3>'
    
    white_svg = re.sub(pattern, replacement, svg_content)
    return white_svg

def create_white_dot_svgs():
    """Create white-dot versions of all existing domino SVGs."""
    source_dir = Path("assets/tiles/dominos")
    target_dir = Path("assets/experimental/dominos_white")
    
    # Create target directory
    target_dir.mkdir(parents=True, exist_ok=True)
    
    converted_count = 0
    
    for svg_file in source_dir.glob("*.svg"):
        try:
            # Read original SVG
            with open(svg_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Convert to white dots
            white_content = convert_svg_to_white_dots(content)
            
            # Write white-dot version
            target_file = target_dir / f"white_{svg_file.name}"
            with open(target_file, 'w', encoding='utf-8') as f:
                f.write(white_content)
            
            converted_count += 1
            
            if converted_count % 50 == 0:
                print(f"Converted {converted_count} SVG files...")
                
        except Exception as e:
            print(f"Error converting {svg_file}: {e}")
    
    print(f"Successfully converted {converted_count} SVG files to white-dot versions")
    return converted_count

def create_shader_material_template():
    """Create a base shader material file that can be customized."""
    material_content = '''[gd_resource type="ShaderMaterial" format=3]

[ext_resource type="Shader" path="res://shaders/domino_dot_color.gdshader" id="1"]

[resource]
shader = ExtResource("1")
shader_parameter/left_dots = 0
shader_parameter/right_dots = 0
shader_parameter/is_vertical = false
'''
    
    target_dir = Path("assets/experimental/materials")
    target_dir.mkdir(parents=True, exist_ok=True)
    
    material_file = target_dir / "domino_shader_base.tres"
    with open(material_file, 'w', encoding='utf-8') as f:
        f.write(material_content)
    
    print(f"Created base shader material: {material_file}")

def create_experimental_domino_scene_template():
    """Create a template domino scene that uses the shader system."""
    scene_content = '''[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/experimental/experimental_domino.gd" id="1"]
[ext_resource type="ShaderMaterial" path="res://assets/experimental/materials/domino_shader_base.tres" id="2"]

[node name="ExperimentalDomino" type="TextureRect"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
material = ExtResource("2")
script = ExtResource("1")

[connection signal="resized" from="." to="." method="_on_resized"]
'''
    
    target_dir = Path("scenes/experimental")
    target_dir.mkdir(parents=True, exist_ok=True)
    
    scene_file = target_dir / "experimental_domino.tscn"
    with open(scene_file, 'w', encoding='utf-8') as f:
        f.write(scene_content)
    
    print(f"Created experimental domino scene template: {scene_file}")

def create_experimental_domino_script():
    """Create the script for experimental domino functionality."""
    script_content = '''extends TextureRect
class_name ExperimentalDomino

## Experimental domino implementation using shaders for dot coloring
## This version pre-loads SVG assets and uses shaders for dynamic coloring

@export var left_dots: int = 0 : set = set_left_dots
@export var right_dots: int = 0 : set = set_right_dots
@export var orientation: String = "top" : set = set_orientation

var base_texture_path: String = "res://assets/experimental/dominos_white/"
var current_domino_key: String = ""

func _ready():
    update_domino_display()

func set_left_dots(value: int):
    left_dots = clamp(value, 0, 18)
    update_shader_parameters()

func set_right_dots(value: int):
    right_dots = clamp(value, 0, 18)
    update_shader_parameters()

func set_orientation(value: String):
    if value in ["top", "bottom", "left", "right"]:
        orientation = value
        update_domino_display()

func update_shader_parameters():
    if material and material is ShaderMaterial:
        var shader_material = material as ShaderMaterial
        shader_material.set_shader_parameter("left_dots", left_dots)
        shader_material.set_shader_parameter("right_dots", right_dots)
        shader_material.set_shader_parameter("is_vertical", orientation in ["top", "bottom"])

func update_domino_display():
    var domino_key = "%d-%d" % [left_dots, right_dots]
    if domino_key == current_domino_key and texture != null:
        return # No change needed
    
    current_domino_key = domino_key
    
    # Load the appropriate white-dot SVG
    var texture_path = base_texture_path + "white_domino-%s_%s.svg" % [domino_key, orientation]
    
    if ResourceLoader.exists(texture_path):
        texture = load(texture_path)
        update_shader_parameters()
    else:
        push_error("Could not find texture: " + texture_path)

func configure_domino(left: int, right: int, orient: String = "top"):
    """Configure the domino with specific dot counts and orientation."""
    left_dots = left
    right_dots = right
    orientation = orient
    update_domino_display()

func get_domino_data() -> Dictionary:
    """Get current domino configuration as data."""
    return {
        "left_dots": left_dots,
        "right_dots": right_dots,
        "orientation": orientation,
        "texture_path": base_texture_path + "white_domino-%s_%s.svg" % [current_domino_key, orientation]
    }
'''
    
    target_dir = Path("scripts/experimental")
    target_dir.mkdir(parents=True, exist_ok=True)
    
    script_file = target_dir / "experimental_domino.gd"
    with open(script_file, 'w', encoding='utf-8') as f:
        f.write(script_content)
    
    print(f"Created experimental domino script: {script_file}")

def create_test_scene():
    """Create a test scene to demonstrate the experimental domino system."""
    test_scene_content = '''[gd_scene load_steps=2 format=3]

[ext_resource type="PackedScene" path="res://scenes/experimental/experimental_domino.tscn" id="1"]

[node name="ExperimentalDominoTest" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0

[node name="VBoxContainer" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 50.0
offset_top = 50.0
offset_right = -50.0
offset_bottom = -50.0

[node name="TitleLabel" type="Label" parent="VBoxContainer"]
layout_mode = 2
text = "Experimental Shader-Based Domino System"
horizontal_alignment = 1

[node name="HBoxContainer" type="HBoxContainer" parent="VBoxContainer"]
layout_mode = 2
size_flags_vertical = 3

[node name="Domino1" parent="VBoxContainer/HBoxContainer" instance=ExtResource("1")]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
left_dots = 1
right_dots = 1

[node name="Domino2" parent="VBoxContainer/HBoxContainer" instance=ExtResource("1")]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
left_dots = 3
right_dots = 6

[node name="Domino3" parent="VBoxContainer/HBoxContainer" instance=ExtResource("1")]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
left_dots = 9
right_dots = 12

[node name="Domino4" parent="VBoxContainer/HBoxContainer" instance=ExtResource("1")]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
left_dots = 15
right_dots = 18

[node name="InstructionsLabel" type="Label" parent="VBoxContainer"]
layout_mode = 2
text = "These dominoes use pre-loaded SVG files with shader-based dot coloring.
Each domino automatically loads the correct SVG and applies colors via shader."
horizontal_alignment = 1
autowrap_mode = 2
'''
    
    target_dir = Path("scenes/experimental")
    target_dir.mkdir(parents=True, exist_ok=True)
    
    test_file = target_dir / "experimental_domino_test.tscn"
    with open(test_file, 'w', encoding='utf-8') as f:
        f.write(test_scene_content)
    
    print(f"Created experimental domino test scene: {test_file}")

def main():
    """Main function to create the experimental domino system."""
    print("Creating experimental shader-based domino system...")
    print("=" * 60)
    print(f"Working directory: {os.getcwd()}")
    print(f"Source directory exists: {Path('assets/tiles/dominos').exists()}")
    
    # Step 1: Create white-dot SVG templates
    print("Step 1: Converting existing SVGs to white-dot versions...")
    converted_count = create_white_dot_svgs()
    
    # Step 2: Create shader material template
    print("\\nStep 2: Creating shader material template...")
    create_shader_material_template()
    
    # Step 3: Create experimental domino script
    print("\\nStep 3: Creating experimental domino script...")
    create_experimental_domino_script()
    
    # Step 4: Create experimental domino scene template
    print("\\nStep 4: Creating experimental domino scene template...")
    create_experimental_domino_scene_template()
    
    # Step 5: Create test scene
    print("\\nStep 5: Creating test scene...")
    create_test_scene()
    
    print("\\n" + "=" * 60)
    print("Experimental domino system creation complete!")
    print(f"- Converted {converted_count} SVG files to white-dot versions")
    print("- Created shader material template")
    print("- Created experimental domino script and scene")
    print("- Created test scene for demonstration")
    print("\\nNext steps:")
    print("1. Open Godot and import the new assets")
    print("2. Run the test scene: scenes/experimental/experimental_domino_test.tscn")
    print("3. Adjust colors in the shader if needed")

if __name__ == "__main__":
    main()
