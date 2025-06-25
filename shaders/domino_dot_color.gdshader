shader_type canvas_item;

// Shader for dynamically coloring domino dots based on the number of dots
// This allows pre-loaded scenes with runtime color changes

// Uniforms for controlling dot colors - direct color approach!
uniform bool is_vertical = false;
uniform vec3 top_color = vec3(1.0, 1.0, 1.0);        // Color for top/left region
uniform vec3 bottom_color = vec3(1.0, 1.0, 1.0);     // Color for bottom/right region

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

// Function to get the appropriate dot color based on position and orientation
vec3 get_dot_color_for_position(vec2 uv, bool vertical) {
    if (vertical) {
        // Vertical domino: top half vs bottom half
        if (uv.y < 0.5) {
            return top_color; // Top half gets top_color
        } else {
            return bottom_color; // Bottom half gets bottom_color
        }
    } else {
        // Horizontal domino: left half vs right half  
        if (uv.x < 0.5) {
            return top_color; // Left half gets top_color (reusing param)
        } else {
            return bottom_color; // Right half gets bottom_color (reusing param)
        }
    }
}

void fragment() {
    vec2 uv = UV;
    vec4 tex_color = texture(TEXTURE, uv);
    
    // Check if this is a black dot pixel
    float black_threshold = 0.2;
    if (tex_color.r < black_threshold && tex_color.g < black_threshold && tex_color.b < black_threshold && tex_color.a > 0.5) {
        // This is a black dot - color it based on position
        vec3 new_color = get_dot_color_for_position(uv, is_vertical);
        COLOR = vec4(new_color, tex_color.a);
    } else if (tex_color.r > 0.95 && tex_color.g > 0.95 && tex_color.b > 0.95 && tex_color.a > 0.5) {
        // This is a white background pixel - replace with cream
        vec3 cream_background = vec3(0.98, 0.97, 0.95); // Warm cream background
        COLOR = vec4(cream_background, tex_color.a);
    } else {
        // Keep original color for divider lines and other elements
        COLOR = tex_color;
    }
}
