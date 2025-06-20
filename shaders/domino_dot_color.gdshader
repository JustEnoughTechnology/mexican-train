shader_type canvas_item;

// Shader for dynamically coloring domino dots based on the number of dots
// This allows pre-loaded scenes with runtime color changes

// Uniforms for controlling dot colors
uniform int left_dots : hint_range(0, 18) = 0;
uniform int right_dots : hint_range(0, 18) = 0;
uniform bool is_vertical : hint_default(false) = false;

// Color palette for dots (0-18)
// Based on domino_dot_colors.txt
const vec3 dot_colors[19] = {
    vec3(1.0, 1.0, 1.0),          // 0 - white (no dots)
    vec3(0.68, 0.85, 1.0),        // 1 - light blue
    vec3(0.0, 0.8, 0.0),          // 2 - green  
    vec3(1.0, 0.75, 0.8),         // 3 - pink
    vec3(0.8, 0.8, 0.6),          // 4 - gray (yellow tinted)
    vec3(0.0, 0.0, 0.8),          // 5 - dark blue
    vec3(1.0, 1.0, 0.0),          // 6 - yellow
    vec3(0.9, 0.7, 1.0),          // 7 - lavender
    vec3(0.0, 0.5, 0.0),          // 8 - dark green
    vec3(0.4, 0.0, 0.8),          // 9 - royal purple
    vec3(1.0, 0.5, 0.0),          // 10 - orange
    vec3(0.0, 0.0, 0.0),          // 11 - black
    vec3(0.5, 0.5, 0.5),          // 12 - gray (normal)
    vec3(0.4, 0.6, 0.8),          // 13 - cadet blue
    vec3(0.4, 0.4, 0.2),          // 14 - dark gray (yellow-tinted)
    vec3(0.6, 0.0, 0.6),          // 15 - classic purple
    vec3(0.0, 0.2, 0.5),          // 16 - oxford blue
    vec3(0.0, 0.8, 0.4),          // 17 - jade green
    vec3(1.0, 0.0, 0.0)           // 18 - red
};

// Function to determine if a pixel is in the left/top half
bool is_left_half(vec2 uv, bool vertical) {
    if (vertical) {
        return uv.y < 0.5; // Top half for vertical
    } else {
        return uv.x < 0.5; // Left half for horizontal
    }
}

// Function to get the appropriate dot color based on position
vec3 get_dot_color_for_position(vec2 uv, bool vertical) {
    if (is_left_half(uv, vertical)) {
        // Left half (or top half if vertical) uses left_dots color
        return dot_colors[clamp(left_dots, 0, 18)];
    } else {
        // Right half (or bottom half if vertical) uses right_dots color
        return dot_colors[clamp(right_dots, 0, 18)];
    }
}

void fragment() {
    vec2 uv = UV;
    vec4 tex_color = texture(TEXTURE, uv);
    
    // If this is a white pixel (likely a dot), recolor it
    if (tex_color.r > 0.9 && tex_color.g > 0.9 && tex_color.b > 0.9) {
        vec3 new_color = get_dot_color_for_position(uv, is_vertical);
        COLOR = vec4(new_color, tex_color.a);
    } else {
        // Keep original color for non-dot pixels
        COLOR = tex_color;
    }
}
