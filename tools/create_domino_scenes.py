#!/usr/bin/env python3
"""
Generate individual Godot scene files for each domino-orientation combination.
This creates pre-colored domino scenes, eliminating the need for complex shader logic.

Each scene will be named: domino-{left}-{right}_{orientation}.tscn
Example: domino-6-3_top.tscn, domino-6-3_bottom.tscn, etc.
"""

import os
import json
from pathlib import Path

# Color mapping from domino_dot_colors.txt
DOT_COLORS = {
    0: (1.0, 1.0, 1.0),          # white (no dots)
    1: (0.68, 0.85, 1.0),        # light blue
    2: (0.0, 0.8, 0.0),          # green  
    3: (1.0, 0.75, 0.8),         # pink
    4: (0.8, 0.8, 0.6),          # gray (yellow tinted)
    5: (0.0, 0.0, 0.8),          # dark blue
    6: (1.0, 1.0, 0.0),          # yellow
    7: (0.9, 0.7, 1.0),          # lavender
    8: (0.0, 0.5, 0.0),          # dark green
    9: (0.4, 0.0, 0.8),          # royal purple
    10: (1.0, 0.5, 0.0),         # orange
    11: (0.0, 0.0, 0.0),         # black
    12: (0.5, 0.5, 0.5),         # gray (normal)
    13: (0.4, 0.6, 0.8),         # cadet blue
    14: (0.4, 0.4, 0.2),         # dark gray (yellow-tinted)
    15: (0.6, 0.0, 0.6),         # classic purple
    16: (0.0, 0.2, 0.5),         # oxford blue
    17: (0.0, 0.8, 0.4),         # jade green
    18: (1.0, 0.0, 0.0)          # red
}

def create_shader_material_resource(left_dots, right_dots, orientation, output_dir):
    """Create a shader material resource file for this domino configuration."""
    
    # Determine which dots get which colors based on orientation
    if orientation in ["top", "left"]:
        # Normal orientation: left_dots get left color, right_dots get right color
        first_color = DOT_COLORS[left_dots]
        second_color = DOT_COLORS[right_dots]
    else:
        # Flipped orientation: swap the colors
        first_color = DOT_COLORS[right_dots]  
        second_color = DOT_COLORS[left_dots]
    
    is_vertical = orientation in ["top", "bottom"]
    
    material_content = f'''[gd_resource type="ShaderMaterial" script_class="" load_steps=2 format=3]

[ext_resource type="Shader" path="res://shaders/domino_dot_color.gdshader" id="1"]

[resource]
shader = ExtResource("1")
shader_parameter/is_vertical = {str(is_vertical).lower()}
shader_parameter/top_color = Vector3({first_color[0]}, {first_color[1]}, {first_color[2]})
shader_parameter/bottom_color = Vector3({second_color[0]}, {second_color[1]}, {second_color[2]})
'''
    
    # Ensure larger number comes first in filename (domino naming convention)
    file_left = max(left_dots, right_dots)
    file_right = min(left_dots, right_dots)
    
    material_filename = f"domino-{file_left}-{file_right}_{orientation}_material.tres"
    material_path = output_dir / "materials" / material_filename
    
    # Create materials directory if it doesn't exist
    material_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(material_path, 'w') as f:
        f.write(material_content)
    
    return f"res://scenes/experimental/dominoes/materials/{material_filename}"

def create_domino_scene(left_dots, right_dots, orientation, output_dir):
    """Create a Godot scene file for a specific domino-orientation combination."""
    
    # Ensure larger number comes first in filename (domino naming convention)
    file_left = max(left_dots, right_dots)
    file_right = min(left_dots, right_dots)
    
    # Create the shader material first
    material_path = create_shader_material_resource(left_dots, right_dots, orientation, output_dir)
    
    # Determine SVG path and dimensions
    svg_path = f"res://assets/experimental/dominos_white/white_domino-{file_left}-{file_right}_{orientation}.svg"
    
    if orientation in ["top", "bottom"]:
        width, height = 40, 82
    else:
        width, height = 82, 40
    
    scene_content = f'''[gd_scene load_steps=3 format=3]

[ext_resource type="Texture2D" path="{svg_path}" id="1"]
[ext_resource type="ShaderMaterial" path="{material_path}" id="2"]

[node name="Domino{file_left}{file_right}{orientation.title()}" type="TextureRect"]
layout_mode = 0
anchors_preset = 0
size = Vector2({width}, {height})
texture = ExtResource("1")
material = ExtResource("2")
'''
    
    scene_filename = f"domino-{file_left}-{file_right}_{orientation}.tscn"
    scene_path = output_dir / scene_filename
    
    with open(scene_path, 'w') as f:
        f.write(scene_content)
    
    return scene_filename

def main():
    """Generate all domino scene files."""
    
    base_dir = Path(__file__).parent.parent
    output_dir = base_dir / "scenes" / "experimental" / "dominoes"
    
    # Create output directory
    output_dir.mkdir(parents=True, exist_ok=True)
    
    orientations = ["top", "bottom", "left", "right"]
    generated_scenes = []
    generated_materials = []
    
    print("Generating domino scenes for all combinations...")
    
    # Generate scenes for all domino combinations (0-18 dots)
    total_combinations = 0
    for left in range(19):  # 0 to 18
        for right in range(left + 1):  # Only generate each combination once (right <= left)
            for orientation in orientations:
                try:
                    scene_file = create_domino_scene(left, right, orientation, output_dir)
                    generated_scenes.append(scene_file)
                    total_combinations += 1
                    
                    if total_combinations % 100 == 0:
                        print(f"Generated {total_combinations} scenes...")
                        
                except Exception as e:
                    print(f"Error generating {left}-{right}_{orientation}: {e}")
    
    # Create an index file for easy reference
    index_data = {
        "description": "Generated domino scenes with pre-colored dots",
        "total_scenes": len(generated_scenes),
        "orientations": orientations,
        "dot_range": "0-18",
        "naming_convention": "domino-{larger}-{smaller}_{orientation}.tscn",
        "scenes": generated_scenes
    }
    
    index_path = output_dir / "scene_index.json"
    with open(index_path, 'w') as f:
        json.dump(index_data, f, indent=2)
    
    print(f"✅ Generated {len(generated_scenes)} domino scene files")
    print(f"✅ Created scene index: {index_path}")
    print(f"✅ Output directory: {output_dir}")
    
    # Create a simple ExperimentalDomino script for the new system
    create_new_experimental_domino_script(base_dir)

def create_new_experimental_domino_script(base_dir):
    """Create a simplified ExperimentalDomino script that uses pre-generated scenes."""
    
    script_content = '''extends Control
class_name ExperimentalDominoV2

## Simplified experimental domino that uses pre-generated scene files
## Each domino-orientation combination has its own scene with pre-colored dots

@export var left_dots: int = 0 : set = set_left_dots
@export var right_dots: int = 0 : set = set_right_dots
@export var orientation: String = "top" : set = set_orientation

var current_scene_instance: Control = null
var base_scene_path: String = "res://scenes/experimental/dominoes/"

func _ready():
    update_domino_display()

func set_left_dots(value: int):
    left_dots = clamp(value, 0, 18)
    update_domino_display()

func set_right_dots(value: int):
    right_dots = clamp(value, 0, 18)
    update_domino_display()

func set_orientation(value: String):
    if value in ["top", "bottom", "left", "right"]:
        orientation = value
        update_domino_display()

func update_domino_display():
    """Load and display the appropriate pre-generated domino scene."""
    
    # Clear existing domino
    if current_scene_instance:
        current_scene_instance.queue_free()
        current_scene_instance = null
    
    # Ensure larger number comes first in filename (domino naming convention)
    var file_left = max(left_dots, right_dots)
    var file_right = min(left_dots, right_dots)
    
    # Construct scene path
    var scene_path = base_scene_path + "domino-%d-%d_%s.tscn" % [file_left, file_right, orientation]
    
    # Load and instantiate the scene
    if ResourceLoader.exists(scene_path):
        var scene_resource = load(scene_path)
        if scene_resource:
            current_scene_instance = scene_resource.instantiate()
            add_child(current_scene_instance)
            
            # Resize this container to match the domino
            if current_scene_instance.has_method("get_size"):
                custom_minimum_size = current_scene_instance.size
                size = current_scene_instance.size
        else:
            push_error("Failed to load domino scene: " + scene_path)
    else:
        push_error("Domino scene not found: " + scene_path)

func configure_domino(left: int, right: int, orient: String = "top"):
    """Configure the domino with specific dot counts and orientation."""
    left_dots = left
    right_dots = right
    orientation = orient

func get_domino_data() -> Dictionary:
    """Get current domino configuration as data."""
    return {
        "left_dots": left_dots,
        "right_dots": right_dots,
        "orientation": orientation,
        "scene_path": base_scene_path + "domino-%d-%d_%s.tscn" % [max(left_dots, right_dots), min(left_dots, right_dots), orientation]
    }
'''
    
    script_path = base_dir / "scripts" / "experimental" / "experimental_domino_v2.gd"
    script_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(script_path, 'w') as f:
        f.write(script_content)
    
    print(f"✅ Created simplified ExperimentalDomino script: {script_path}")

if __name__ == "__main__":
    main()
'''
