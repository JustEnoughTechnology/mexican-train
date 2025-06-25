extends Control
class_name DominoTile

enum Orientation {
	HORIZONTAL_LEFT,   # Largest on left, smallest on right
	HORIZONTAL_RIGHT,  # Largest on right, smallest on left  
	VERTICAL_TOP,      # Largest on top, smallest on bottom
	VERTICAL_BOTTOM    # Largest on bottom, smallest on top
}

@export var largest_value: int = 6 : set = set_largest_value
@export var smallest_value: int = 3 : set = set_smallest_value
@export var orientation: DominoTile.Orientation = DominoTile.Orientation.HORIZONTAL_LEFT : set = set_orientation

@onready var horizontal_layout = $HorizontalLayout
@onready var vertical_layout = $VerticalLayout

# Half domino texture paths
var half_textures: Array[String] = [
	"res://assets/dominos/half/half-0.svg",
	"res://assets/dominos/half/half-1.svg",
	"res://assets/dominos/half/half-2.svg",
	"res://assets/dominos/half/half-3.svg",
	"res://assets/dominos/half/half-4.svg",
	"res://assets/dominos/half/half-5.svg",
	"res://assets/dominos/half/half-6.svg",
	"res://assets/dominos/half/half-7.svg",
	"res://assets/dominos/half/half-8.svg",
	"res://assets/dominos/half/half-9.svg",
	"res://assets/dominos/half/half-10.svg",
	"res://assets/dominos/half/half-11.svg",
	"res://assets/dominos/half/half-12.svg"
]

func _ready():
	update_domino_display()

func set_largest_value(value: int):
	largest_value = clamp(value, 0, 12)
	if is_inside_tree():
		update_domino_display()

func set_smallest_value(value: int):
	smallest_value = clamp(value, 0, 12)
	if is_inside_tree():
		update_domino_display()

func set_orientation(value: DominoTile.Orientation):
	orientation = value
	if is_inside_tree():
		update_domino_display()

func update_domino_display():
	if not is_inside_tree():
		return
		
	# Load textures
	var largest_texture = load(half_textures[largest_value])
	var smallest_texture = load(half_textures[smallest_value])
	
	# Hide both layouts first
	horizontal_layout.visible = false
	vertical_layout.visible = false
	
	match orientation:
		DominoTile.Orientation.HORIZONTAL_LEFT:
			_setup_horizontal_layout(largest_texture, smallest_texture, false)
		DominoTile.Orientation.HORIZONTAL_RIGHT:
			_setup_horizontal_layout(largest_texture, smallest_texture, true)
		DominoTile.Orientation.VERTICAL_TOP:
			_setup_vertical_layout(largest_texture, smallest_texture, false)
		DominoTile.Orientation.VERTICAL_BOTTOM:
			_setup_vertical_layout(largest_texture, smallest_texture, true)

func _setup_horizontal_layout(largest_tex: Texture2D, smallest_tex: Texture2D, reverse: bool):
	horizontal_layout.visible = true
	var largest_node = horizontal_layout.get_node("LargestHalf")
	var smallest_node = horizontal_layout.get_node("SmallestHalf")
	
	if reverse:
		# Largest on right, smallest on left
		largest_node.texture = largest_tex
		smallest_node.texture = smallest_tex
		# Move largest to end
		horizontal_layout.move_child(largest_node, -1)
	else:
		# Largest on left, smallest on right  
		largest_node.texture = largest_tex
		smallest_node.texture = smallest_tex
		# Move largest to beginning
		horizontal_layout.move_child(largest_node, 0)

func _setup_vertical_layout(largest_tex: Texture2D, smallest_tex: Texture2D, reverse: bool):
	vertical_layout.visible = true
	var largest_node = vertical_layout.get_node("LargestHalf")
	var smallest_node = vertical_layout.get_node("SmallestHalf")
	
	if reverse:
		# Largest on bottom, smallest on top
		largest_node.texture = largest_tex
		smallest_node.texture = smallest_tex
		# Move largest to end
		vertical_layout.move_child(largest_node, -1)
	else:
		# Largest on top, smallest on bottom
		largest_node.texture = largest_tex
		smallest_node.texture = smallest_tex
		# Move largest to beginning
		vertical_layout.move_child(largest_node, 0)

# Utility function to get domino identifier string
func get_domino_string() -> String:
	return "%d-%d" % [largest_value, smallest_value]

# Utility function to check if this is a double
func is_double() -> bool:
	return largest_value == smallest_value
