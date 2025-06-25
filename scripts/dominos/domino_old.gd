extends Control
class_name DominoFull

enum Orientation {
	HORIZONTAL_LEFT,   # Largest on left, smallest on right
	HORIZONTAL_RIGHT,  # Largest on right, smallest on left  
	VERTICAL_TOP,      # Largest on top, smallest on bottom
	VERTICAL_BOTTOM    # Largest on bottom, smallest on top
}

@export var largest_value: int = 6 : set = set_largest_value
@export var smallest_value: int = 3 : set = set_smallest_value
@export var orientation: DominoFull.Orientation = DominoFull.Orientation.HORIZONTAL_LEFT : set = set_orientation

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
	# Only update display if values are set
	if largest_value >= 0 and smallest_value >= 0:
		update_domino_display()

func set_largest_value(value: int):
	largest_value = clamp(value, 0, 12)
	if is_inside_tree():
		update_domino_display()

func set_smallest_value(value: int):
	smallest_value = clamp(value, 0, 12)
	if is_inside_tree():
		update_domino_display()

func set_orientation(value: DominoFull.Orientation):
	orientation = value
	if is_inside_tree():
		update_domino_display()

func update_domino_display():
	# Wait for scene to be ready
	if not is_inside_tree():
		return
		
	# Load textures
	var largest_texture = load(half_textures[largest_value])
	var smallest_texture = load(half_textures[smallest_value])
	
	# Setup based on orientation
	match orientation:
		DominoFull.Orientation.HORIZONTAL_LEFT:
			_setup_horizontal_layout(largest_texture, smallest_texture, false)
		DominoFull.Orientation.HORIZONTAL_RIGHT:
			_setup_horizontal_layout(largest_texture, smallest_texture, true)
		DominoFull.Orientation.VERTICAL_TOP:
			_setup_vertical_layout(largest_texture, smallest_texture, false)
		DominoFull.Orientation.VERTICAL_BOTTOM:
			_setup_vertical_layout(largest_texture, smallest_texture, true)

func _setup_horizontal_layout(largest_tex: Texture2D, smallest_tex: Texture2D, reverse: bool):
	# Ensure nodes exist before accessing them
	if not horizontal_layout or not vertical_layout:
		return
		
	horizontal_layout.visible = true
	vertical_layout.visible = false
	
	# Get texture nodes safely
	var largest_node = horizontal_layout.get_node_or_null("LargestHalf")
	var smallest_node = horizontal_layout.get_node_or_null("SmallestHalf")
	
	if not largest_node or not smallest_node:
		return
	
	if reverse:
		# Largest on right, smallest on left
		smallest_node.texture = smallest_tex
		largest_node.texture = largest_tex
		# Move largest to end
		horizontal_layout.move_child(largest_node, -1)
	else:
		# Largest on left, smallest on right
		largest_node.texture = largest_tex
		smallest_node.texture = smallest_tex
		# Move largest to beginning
		horizontal_layout.move_child(largest_node, 0)

func _setup_vertical_layout(largest_tex: Texture2D, smallest_tex: Texture2D, reverse: bool):
	# Ensure nodes exist before accessing them
	if not horizontal_layout or not vertical_layout:
		return
		
	horizontal_layout.visible = false
	vertical_layout.visible = true
	
	# Get texture nodes safely
	var largest_node = vertical_layout.get_node_or_null("LargestHalf")
	var smallest_node = vertical_layout.get_node_or_null("SmallestHalf")
	
	if not largest_node or not smallest_node:
		return
	
	if reverse:
		# Largest on bottom, smallest on top
		smallest_node.texture = smallest_tex
		largest_node.texture = largest_tex
		# Move largest to end
		vertical_layout.move_child(largest_node, -1)
	else:
		# Largest on top, smallest on bottom
		largest_node.texture = largest_tex
		smallest_node.texture = smallest_tex
		# Move largest to beginning
		vertical_layout.move_child(largest_node, 0)
