extends Control
class_name DominoExperimental

## Lightweight domino wrapper that loads pre-built BaseDomino scenes
## This replaces the old dynamic domino system with static scene loading

# Signals - for compatibility with old Domino class
signal orientation_changed(new_orientation: NewDomino.Orientation, old_orientation: NewDomino.Orientation)
signal face_changed(is_face_up: bool)
@warning_ignore("unused_signal")
signal mouse_right_pressed(p_domino: NewDomino)
@warning_ignore("unused_signal")
signal domino_dropped(target: NewDomino, dropped: NewDomino)

enum Orientation {
	HORIZONTAL_LEFT,   # Largest on left, smallest on right (0, 0)
	HORIZONTAL_RIGHT,  # Largest on right, smallest on left (0, 1)
	VERTICAL_TOP,      # Largest on top, smallest on bottom (1, 0)
	VERTICAL_BOTTOM    # Largest on bottom, smallest on top (1, 1)
}

@export var largest_value: int = 6 : set = set_largest_value
@export var smallest_value: int = 3 : set = set_smallest_value
@export var orientation: NewDomino.Orientation = NewDomino.Orientation.HORIZONTAL_LEFT : set = set_orientation
@export var face_up: bool = true : set = set_face_up

# Current loaded BaseDomino instance (face) or back scene
var current_base_domino: Control = null

func _ready():
	# Load the appropriate BaseDomino scene
	if largest_value >= 0 and smallest_value >= 0:
		load_domino_scene()

func set_largest_value(value: int):
	var old_largest = largest_value
	largest_value = clamp(value, 0, 12)
	if is_inside_tree() and old_largest != largest_value:
		load_domino_scene()

func set_smallest_value(value: int):
	var old_smallest = smallest_value
	smallest_value = clamp(value, 0, 12)
	if is_inside_tree() and old_smallest != smallest_value:
		load_domino_scene()

func set_orientation(value: NewDomino.Orientation):
	var old_orientation = orientation
	orientation = value
	if is_inside_tree() and old_orientation != orientation:
		load_domino_scene()
		# Emit signal for future system integration
		orientation_changed.emit(orientation, old_orientation)

func set_face_up(value: bool):
	var old_face_up = face_up
	face_up = value
	if is_inside_tree() and old_face_up != face_up:
		load_domino_scene()
		# Emit signal for future system integration
		face_changed.emit(face_up)

func load_domino_scene():
	"""Load the appropriate scene based on face_up state."""
	# Clear existing scene
	if current_base_domino != null:
		remove_child(current_base_domino)
		current_base_domino.queue_free()
		current_base_domino = null
	
	var scene_path: String
	if face_up:
		scene_path = get_base_domino_scene_path()
	else:
		scene_path = get_domino_back_scene_path()
	
	# Load the scene
	var scene = load(scene_path)
	if scene == null:
		print("ERROR: Could not load domino scene: ", scene_path)
		return
		# Instantiate and add to our scene
	current_base_domino = scene.instantiate()
	add_child(current_base_domino)
	
	# Don't force full rect - let the scene maintain its own size

func get_base_domino_scene_path() -> String:
	"""Get the file path for the appropriate BaseDomino scene."""
	
	# Ensure largest >= smallest (swap if needed)
	var actual_largest = max(largest_value, smallest_value)
	var actual_smallest = min(largest_value, smallest_value)
	
	# Determine orientation suffix
	var orientation_suffix: String
	match orientation:
		Orientation.HORIZONTAL_LEFT:
			orientation_suffix = "horizontal_left"
		Orientation.HORIZONTAL_RIGHT:
			orientation_suffix = "horizontal_right"
		Orientation.VERTICAL_TOP:
			orientation_suffix = "vertical_top"
		Orientation.VERTICAL_BOTTOM:
			orientation_suffix = "vertical_bottom"
		_:
			orientation_suffix = "horizontal_left"  # fallback
	
	# Build the path
	return "res://scenes/dominos/base_dominos/base_domino_%d_%d_%s.tscn" % [
		actual_largest, actual_smallest, orientation_suffix
	]

func get_domino_back_scene_path() -> String:
	"""Get the file path for the appropriate back scene."""
	match orientation:
		Orientation.HORIZONTAL_LEFT, Orientation.HORIZONTAL_RIGHT:
			return "res://scenes/dominos/domino_back_horizontal.tscn"
		Orientation.VERTICAL_TOP, Orientation.VERTICAL_BOTTOM:
			return "res://scenes/dominos/domino_back_vertical.tscn"
		_:
			return "res://scenes/dominos/domino_back_horizontal.tscn"  # fallback

func get_domino_info() -> Dictionary:
	"""Get information about this domino."""
	return {
		"largest_value": largest_value,
		"smallest_value": smallest_value,
		"orientation": orientation,
		"orientation_string": get_orientation_string(),
		"scene_path": get_base_domino_scene_path()
	}

func get_orientation_string() -> String:
	"""Get a human-readable orientation string."""
	match orientation:
		Orientation.HORIZONTAL_LEFT:
			return "horizontal_left"
		Orientation.HORIZONTAL_RIGHT:
			return "horizontal_right"
		Orientation.VERTICAL_TOP:
			return "vertical_top"
		Orientation.VERTICAL_BOTTOM:
			return "vertical_bottom"
		_:
			return "unknown"

func get_expected_size() -> Vector2:
	"""Get the expected size for this domino orientation."""
	match orientation:
		Orientation.HORIZONTAL_LEFT, Orientation.HORIZONTAL_RIGHT:
			return Vector2(81, 40)  # horizontal: 40+1+40 wide, 40 tall
		Orientation.VERTICAL_TOP, Orientation.VERTICAL_BOTTOM:
			return Vector2(40, 81)  # vertical: 40 wide, 40+1+40 tall
		_:
			return Vector2(81, 40)  # fallback

# Compatibility methods for old DominoFull interface
func get_total_dots() -> int:
	"""Get the total number of dots on this domino."""
	return largest_value + smallest_value

func is_double() -> bool:
	"""Check if this is a double domino (same value on both sides)."""
	return largest_value == smallest_value

func can_connect_to(other_domino: NewDomino) -> bool:
	"""Check if this domino can connect to another domino."""
	if other_domino == null:
		return false
	
	return (largest_value == other_domino.largest_value or 
			largest_value == other_domino.smallest_value or
			smallest_value == other_domino.largest_value or
			smallest_value == other_domino.smallest_value)

# Face manipulation methods for compatibility with old domino interface
func toggle_face():
	"""Toggle between face up and face down."""
	set_face_up(!face_up)

func is_face_up() -> bool:
	"""Check if domino is face up."""
	return face_up