#!/usr/bin/env python3
"""
Simple test script to generate a few domino scenes.
"""

import os
from pathlib import Path

print("Starting domino scene generation...")

# Color mapping
DOT_COLORS = {
    0: (1.0, 1.0, 1.0),          # white (no dots)
    1: (0.68, 0.85, 1.0),        # light blue
    2: (0.0, 0.8, 0.0),          # green  
    3: (1.0, 0.75, 0.8),         # pink
    4: (0.8, 0.8, 0.6),          # gray (yellow tinted)
    5: (0.0, 0.0, 0.8),          # dark blue
    6: (1.0, 1.0, 0.0),          # yellow
}

def create_simple_domino_scene(left_dots, right_dots, orientation, output_dir):
    """Create a simple domino scene file."""
    
    print(f"Creating scene for {left_dots}-{right_dots}_{orientation}")
    
    # Ensure larger number comes first in filename
    file_left = max(left_dots, right_dots)
    file_right = min(left_dots, right_dots)
    
    # Determine colors based on orientation
    if orientation in ["top", "left"]:
        first_color = DOT_COLORS[left_dots]
        second_color = DOT_COLORS[right_dots]
    else:
        first_color = DOT_COLORS[right_dots]  
        second_color = DOT_COLORS[left_dots]
    
    is_vertical = orientation in ["top", "bottom"]
    
    # SVG path
    svg_path = f"res://assets/experimental/dominos_white/white_domino-{file_left}-{file_right}_{orientation}.svg"
    
    # Dimensions
    if orientation in ["top", "bottom"]:
        width, height = 40, 82
    else:
        width, height = 82, 40
    
    # Create shader material content
    material_content = f'''[gd_resource type="ShaderMaterial" script_class="" load_steps=2 format=3]

[ext_resource type="Shader" path="res://shaders/domino_dot_color.gdshader" id="1"]

[resource]
shader = ExtResource("1")
shader_parameter/is_vertical = {str(is_vertical).lower()}
shader_parameter/top_color = Vector3({first_color[0]}, {first_color[1]}, {first_color[2]})
shader_parameter/bottom_color = Vector3({second_color[0]}, {second_color[1]}, {second_color[2]})
'''
    
    # Create scene content
    scene_content = f'''[gd_scene load_steps=3 format=3]

[ext_resource type="Texture2D" path="{svg_path}" id="1"]

[sub_resource type="Shader" id="shader_1"]
code = "
shader_type canvas_item;

uniform bool is_vertical = false;
uniform vec3 top_color = vec3(1.0, 1.0, 1.0);
uniform vec3 bottom_color = vec3(1.0, 1.0, 1.0);

vec3 get_dot_color_for_position(vec2 uv, bool vertical) {{
    if (vertical) {{
        if (uv.y < 0.5) {{
            return top_color;
        }} else {{
            return bottom_color;
        }}
    }} else {{
        if (uv.x < 0.5) {{
            return top_color;
        }} else {{
            return bottom_color;
        }}
    }}
}}

void fragment() {{
    vec2 uv = UV;
    vec4 tex_color = texture(TEXTURE, uv);
    
    float white_threshold = 0.95;
    if (tex_color.r > white_threshold && tex_color.g > white_threshold && tex_color.b > white_threshold && tex_color.a > 0.5) {{
        vec3 new_color = get_dot_color_for_position(uv, is_vertical);
        COLOR = vec4(new_color, tex_color.a);
    }} else {{
        COLOR = tex_color;
    }}
}}
"

[sub_resource type="ShaderMaterial" id="material_1"]
shader = SubResource("shader_1")
shader_parameter/is_vertical = {str(is_vertical).lower()}
shader_parameter/top_color = Vector3({first_color[0]}, {first_color[1]}, {first_color[2]})
shader_parameter/bottom_color = Vector3({second_color[0]}, {second_color[1]}, {second_color[2]})

[node name="Domino{file_left}{file_right}{orientation.title()}" type="TextureRect"]
layout_mode = 0
anchors_preset = 0
size = Vector2({width}, {height})
texture = ExtResource("1")
material = SubResource("material_1")
'''
    
    # Write the scene file
    scene_filename = f"domino-{file_left}-{file_right}_{orientation}.tscn"
    scene_path = output_dir / scene_filename
    
    print(f"Writing to: {scene_path}")
    
    with open(scene_path, 'w') as f:
        f.write(scene_content)
    
    return scene_filename

def main():
    print("Setting up directories...")
    
    base_dir = Path(__file__).parent.parent
    output_dir = base_dir / "scenes" / "experimental" / "dominoes"
    
    print(f"Output directory: {output_dir}")
    
    # Create output directory
    output_dir.mkdir(parents=True, exist_ok=True)
    print("Created output directory")
    
    # Generate just a few test scenes
    test_cases = [
        (1, 0, "top"),
        (6, 3, "top"),
        (6, 3, "bottom"),
        (6, 3, "left"),
        (6, 3, "right")
    ]
    
    generated_scenes = []
    
    for left, right, orientation in test_cases:
        try:
            scene_file = create_simple_domino_scene(left, right, orientation, output_dir)
            generated_scenes.append(scene_file)
            print(f"✅ Generated: {scene_file}")
        except Exception as e:
            print(f"❌ Error generating {left}-{right}_{orientation}: {e}")
    
    print(f"✅ Generated {len(generated_scenes)} test domino scenes")
    print("Test completed!")

if __name__ == "__main__":
    main()
