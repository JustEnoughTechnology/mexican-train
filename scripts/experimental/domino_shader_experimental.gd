class_name DominoShaderExperimental
extends ColorRect
## Experimental shader-based domino implementation
## Uses pre-loaded scenes with dynamic shader-based dot coloring

var left_dots: int = 0
var right_dots: int = 0
var is_vertical: bool = false

@onready var texture_rect: TextureRect = null
var shader_material: ShaderMaterial = null

# Color definitions matching domino_dot_colors.txt
const DOT_COLORS = [
	Color.WHITE,                    # 0 - white (no dots)
	Color(0.68, 0.85, 1.0),        # 1 - light blue
	Color(0.0, 0.8, 0.0),          # 2 - green  
	Color(1.0, 0.75, 0.8),         # 3 - pink
	Color(0.8, 0.8, 0.6),          # 4 - gray (yellow tinted)
	Color(0.0, 0.0, 0.8),          # 5 - dark blue
	Color(1.0, 1.0, 0.0),          # 6 - yellow
	Color(0.9, 0.7, 1.0),          # 7 - lavender
	Color(0.0, 0.5, 0.0),          # 8 - dark green
	Color(0.4, 0.0, 0.8),          # 9 - royal purple
	Color(1.0, 0.5, 0.0),          # 10 - orange
	Color(0.0, 0.0, 0.0),          # 11 - black
	Color(0.5, 0.5, 0.5),          # 12 - gray (normal)
	Color(0.4, 0.6, 0.8),          # 13 - cadet blue
	Color(0.4, 0.4, 0.2),          # 14 - dark gray (yellow-tinted)
	Color(0.6, 0.0, 0.6),          # 15 - classic purple
	Color(0.0, 0.2, 0.5),          # 16 - oxford blue
	Color(0.0, 0.8, 0.4),          # 17 - jade green
	Color(1.0, 0.0, 0.0)           # 18 - red
]

func _ready():
	# Set up the experimental domino
	setup_domino()

func setup_domino():
	# Create the TextureRect for the domino visual
	texture_rect = TextureRect.new()
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	
	# Add to a center container for proper positioning
	var container = CenterContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(container)
	container.add_child(texture_rect)
	
	# Load the shader material
	shader_material = load("res://shaders/domino_dot_color_material.tres")
	texture_rect.material = shader_material
	
	# Set initial values
	set_domino_values(0, 0, false)

func set_domino_values(p_left_dots: int, p_right_dots: int, p_is_vertical: bool = false):
	"""Set the domino values and update the shader parameters"""
	left_dots = p_left_dots
	right_dots = p_right_dots
	is_vertical = p_is_vertical
	
	# Update shader parameters
	if shader_material:
		shader_material.set_shader_parameter("left_dots", left_dots)
		shader_material.set_shader_parameter("right_dots", right_dots)
		shader_material.set_shader_parameter("is_vertical", is_vertical)
	
	# Load appropriate base texture
	var texture_path = get_base_texture_path()
	if texture_rect and ResourceLoader.exists(texture_path):
		texture_rect.texture = load(texture_path)
	
	# Update size based on orientation
	var target_size = Vector2(82, 40) if not is_vertical else Vector2(40, 82)
	custom_minimum_size = target_size
	size = target_size

func get_base_texture_path() -> String:
	"""Get the path to the base texture for the current orientation"""
	var orientation_suffix = "_left" if not is_vertical else "_top"
	
	# Use a template domino with maximum dots to ensure all dot positions exist
	# The shader will handle hiding/showing and coloring dots appropriately
	return "res://assets/experimental/domino_template%s.svg" % orientation_suffix

func set_orientation(vertical: bool):
	"""Change orientation of the domino"""
	set_domino_values(left_dots, right_dots, vertical)

func get_dot_color(dot_count: int) -> Color:
	"""Get the color for a specific dot count"""
	if dot_count >= 0 and dot_count < DOT_COLORS.size():
		return DOT_COLORS[dot_count]
	return Color.WHITE

# Convenience functions for compatibility with existing Domino class
func set_dots(p_left: int, p_right: int):
	set_domino_values(p_left, p_right, is_vertical)

func get_dots() -> Vector2i:
	return Vector2i(left_dots, right_dots)
