extends Control
class_name BaseDomino

# Orientation constants for first index (layout direction)
const HORIZONTAL = 0
const VERTICAL = 1

# Orientation constants for second index (position)
const LEFT = 0    # For horizontal dominos
const TOP = 0     # For vertical dominos  
const RIGHT = 1   # For horizontal dominos
const BOTTOM = 1  # For vertical dominos

# This class represents a single, pre-built domino with specific dot values and orientation
# It's a static scene that contains the exact SVG layout - no dynamic content

@export var largest_value: int = 0
@export var smallest_value: int = 0 
@export var orientation: Vector2i = Vector2i(HORIZONTAL, LEFT)  # [direction, position]

# The actual visual components - set up in the scene file
@onready var domino_visual: Control = $DominoVisual

func _ready():
	# BaseDomino is completely static - all layout is done in the scene file
	# This class just holds metadata about what this domino represents
	pass

func get_orientation_string() -> String:
	# Convert Vector2i orientation to readable string for file naming
	var direction = "horizontal" if orientation.x == HORIZONTAL else "vertical"
	var pos_name = ""
	
	if orientation.x == HORIZONTAL:
		pos_name = "left" if orientation.y == LEFT else "right"
	else:  # VERTICAL
		pos_name = "top" if orientation.y == TOP else "bottom"
	
	return "%s_%s" % [direction, pos_name]

func get_domino_info() -> Dictionary:
	return {
		"largest": largest_value,
		"smallest": smallest_value, 
		"orientation": orientation,
		"orientation_string": get_orientation_string(),
		"name": "base_domino_%d_%d_%s" % [largest_value, smallest_value, get_orientation_string()],
		"size": get_expected_size()
	}

func get_expected_size() -> Vector2i:
	# Calculate expected pixel size based on orientation
	if orientation.x == HORIZONTAL:
		return Vector2i(81, 40)  # 40px + 1px + 40px width, 40px height
	else:  # VERTICAL
		return Vector2i(40, 81)  # 40px width, 40px + 1px + 40px height
