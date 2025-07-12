extends Control
class_name Domino

## Lightweight domino wrapper that loads pre-built BaseDomino scenes
## This replaces the old dynamic domino system with static scene loading

# Essential signals for compatibility with existing game systems
signal mouse_right_pressed(p_domino: Domino)
signal domino_dropped(target: Domino, dropped: Domino)

# Face up/down state for domino backs
@export var is_face_up: bool = true : set = set_face_up

# Highlighting state (used in drag/drop operations)
var is_highlighted: bool = false
var old_modulate: Color = Color.WHITE

# Drag and drop state
var is_being_dragged: bool = false

enum Orientation {
	HORIZONTAL_LEFT,   # Largest on left, smallest on right (0, 0)
	HORIZONTAL_RIGHT,  # Largest on right, smallest on left (0, 1)
	VERTICAL_TOP,      # Largest on top, smallest on bottom (1, 0)
	VERTICAL_BOTTOM    # Largest on bottom, smallest on top (1, 1)
}

@export var largest_value: int = 6 : set = set_largest_value
@export var smallest_value: int = 3 : set = set_smallest_value
@export var orientation: Domino.Orientation = Domino.Orientation.HORIZONTAL_LEFT : set = set_orientation

# Current loaded BaseDomino instance
var current_base_domino: Control = null

func _ready():
	# Load the appropriate BaseDomino scene
	if largest_value >= 0 and smallest_value >= 0:
		load_base_domino_scene()

func set_largest_value(value: int):
	var old_largest = largest_value
	largest_value = clamp(value, 0, 12)
	if is_inside_tree() and old_largest != largest_value:
		load_base_domino_scene()

func set_smallest_value(value: int):
	var old_smallest = smallest_value
	smallest_value = clamp(value, 0, 12)
	if is_inside_tree() and old_smallest != smallest_value:
		load_base_domino_scene()

func set_orientation(value: Domino.Orientation):
	var old_orientation = orientation
	orientation = value
	if is_inside_tree() and old_orientation != orientation:
		load_base_domino_scene()

func load_base_domino_scene():
	"""Load the appropriate pre-built BaseDomino scene based on current values."""
	
	# Remove existing BaseDomino if present
	if current_base_domino:
		current_base_domino.queue_free()
		current_base_domino = null
	
	# Build the scene path
	var scene_path = get_base_domino_scene_path()
	
	# Load the scene
	var scene = load(scene_path)
	if scene == null:
		print("ERROR: Could not load BaseDomino scene: ", scene_path)
		return
	
	# Instantiate and add to our scene
	current_base_domino = scene.instantiate()
	add_child(current_base_domino)
	
	# Make sure it fills our container
	current_base_domino.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

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

func can_connect_to(other_domino: Domino) -> bool:
	"""Check if this domino can connect to another domino."""
	if other_domino == null:
		return false
	
	return (largest_value == other_domino.largest_value or 
			largest_value == other_domino.smallest_value or
			smallest_value == other_domino.largest_value or
			smallest_value == other_domino.smallest_value)

# === COMPATIBILITY METHODS FOR OLD DOMINO INTERFACE ===

func set_face_up(value: bool):
	"""Set whether the domino is face up or face down."""
	var old_face_up = is_face_up
	is_face_up = value
	if is_inside_tree() and old_face_up != is_face_up:
		load_domino_scene()

func load_domino_scene():
	"""Load either front (BaseDomino) or back scene based on face up/down state."""
	if is_face_up:
		load_base_domino_scene()
	else:
		load_domino_back_scene()

func load_domino_back_scene():
	"""Load the appropriate domino back scene."""
	# Remove existing domino if present
	if current_base_domino:
		current_base_domino.queue_free()
		current_base_domino = null
	
	# Determine back scene path based on orientation
	var back_scene_path: String
	if orientation == Orientation.HORIZONTAL_LEFT or orientation == Orientation.HORIZONTAL_RIGHT:
		back_scene_path = "res://scenes/dominos/domino_back_horizontal.tscn"
	else:
		back_scene_path = "res://scenes/dominos/domino_back_vertical.tscn"
	
	# Load and instantiate the back scene
	var scene = load(back_scene_path)
	if scene == null:
		print("ERROR: Could not load domino back scene: ", back_scene_path)
		return
	
	current_base_domino = scene.instantiate()
	add_child(current_base_domino)
	
	# Set proper size (don't use full rect for backs)
	current_base_domino.custom_minimum_size = get_expected_size()

# Old domino interface compatibility
func get_dots() -> Vector2:
	"""Get domino dot values as Vector2 for compatibility."""
	return Vector2(largest_value, smallest_value)

func set_dots(left: int, right: int):
	"""Set domino dot values from individual values."""
	largest_value = max(left, right)
	smallest_value = min(left, right)

func toggle_dots():
	"""Toggle face up/down state for compatibility."""
	set_face_up(not is_face_up)

func set_face_up_legacy(face_up: bool):
	"""Legacy method name for compatibility."""
	set_face_up(face_up)

# Mouse event handling for signals
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Emit the right-click signal
			mouse_right_pressed.emit(self)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Start drag operation
			is_being_dragged = true

# Drag and drop support
func _get_drag_data(_position):
	"""Handle drag start for compatibility with old system."""
	if not is_being_dragged:
		return null
	
	# Create drag preview (simplified version)
	var preview = duplicate()
	preview.modulate.a = 0.7
	set_drag_preview(preview)
	
	return self

func _can_drop_data(_position, data):
	"""Check if we can accept dropped data."""
	return data is Domino

func _drop_data(_position, data):
	"""Handle data being dropped on this domino."""
	if data is Domino:
		domino_dropped.emit(self, data)

# Highlighting support for drag/drop
func highlight():
	"""Highlight this domino for drag/drop feedback."""
	if not is_highlighted:
		old_modulate = modulate
		modulate = Color(1.2, 1.2, 1.2, 1.0)
		is_highlighted = true

func unhighlight():
	"""Remove highlight from this domino."""
	if is_highlighted:
		modulate = old_modulate
		is_highlighted = false
