# domino_2_d.gd
# Hybrid Domino2D: combines dominos/domino_new.gd visuals/logic and domino/domino.gd interface/signals
extends Control
class_name Domino2D

signal mouse_right_pressed(p_domino)
signal domino_dropped(target, dropped)

var is_highlighted: bool = false
var old_modulate: Color = Color.WHITE
var is_being_dragged: bool = false
var show_orientation_label: bool = false

enum Orientation {
	HORIZONTAL_LEFT,
	HORIZONTAL_RIGHT,
	VERTICAL_TOP,
	VERTICAL_BOTTOM
}
var largest_value: int = 6
var smallest_value: int = 5
var orientation = Orientation.HORIZONTAL_LEFT
var is_face_up: bool = true

var current_base_domino: Control = null

func _ready():
	load_domino_scene()

func set_dots(left: int, right: int) -> void:
	largest_value = max(left, right)
	smallest_value = min(left, right)
	if is_inside_tree():
		load_domino_scene()

func get_dots() -> Vector2:
	return Vector2(largest_value, smallest_value)

func set_orientation(new_orientation: int) -> void:
	orientation = Orientation.values()[int(new_orientation)]
	if is_inside_tree():
		load_domino_scene()
	# Always set pivot to center for free domino rotation
	set_pivot_to_center()

func set_pivot_to_center() -> void:
	# Set the pivot to the center of the node for proper rotation
	pivot_offset = size * 0.5

func set_face_up(value: bool = true) -> void:
	is_face_up = value
	if is_inside_tree():
		load_domino_scene()

func toggle_dots() -> void:
	set_face_up(not is_face_up)

func highlight(is_on: bool = true) -> void:
	if is_on and not is_highlighted:
		old_modulate = modulate
		modulate = Color(1.2, 1.2, 1.2, 1.0)
		is_highlighted = true
	elif not is_on and is_highlighted:
		modulate = old_modulate
		is_highlighted = false

func load_domino_scene():
	if is_face_up:
		load_base_domino_scene()
	else:
		load_domino_back_scene()

func load_base_domino_scene():
	if current_base_domino:
		current_base_domino.queue_free()
		current_base_domino = null
	var scene_path = get_base_domino_scene_path()
	var scene = load(scene_path)
	if scene == null:
		print("ERROR: Could not load BaseDomino scene: ", scene_path)
		return
	current_base_domino = scene.instantiate()
	add_child(current_base_domino)
	current_base_domino.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func load_domino_back_scene():
	if current_base_domino:
		current_base_domino.queue_free()
		current_base_domino = null
	var back_scene_path: String
	if orientation == Orientation.HORIZONTAL_LEFT or orientation == Orientation.HORIZONTAL_RIGHT:
		back_scene_path = "res://scenes/dominos/domino_back_horizontal.tscn"
	else:
		back_scene_path = "res://scenes/dominos/domino_back_vertical.tscn"
	var scene = load(back_scene_path)
	if scene == null:
		print("ERROR: Could not load domino back scene: ", back_scene_path)
		return
	current_base_domino = scene.instantiate()
	add_child(current_base_domino)
	current_base_domino.custom_minimum_size = get_expected_size()

func get_base_domino_scene_path() -> String:
	var actual_largest = max(largest_value, smallest_value)
	var actual_smallest = min(largest_value, smallest_value)
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
			orientation_suffix = "horizontal_left"
	return "res://scenes/dominos/base_dominos/base_domino_%d_%d_%s.tscn" % [actual_largest, actual_smallest, orientation_suffix]

func get_expected_size() -> Vector2:
	match orientation:
		Orientation.HORIZONTAL_LEFT, Orientation.HORIZONTAL_RIGHT:
			return Vector2(81, 40)
		Orientation.VERTICAL_TOP, Orientation.VERTICAL_BOTTOM:
			return Vector2(40, 81)
		_:
			return Vector2(81, 40)

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			mouse_right_pressed.emit(self)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			is_being_dragged = true

func _get_drag_data(_position):
	if not is_being_dragged:
		return null
	var preview = duplicate()
	preview.modulate.a = 0.7
	set_drag_preview(preview)
	return self

func _can_drop_data(_position, data):
	return data is Domino2D

func _drop_data(_position, data):
	if data is Domino2D:
		domino_dropped.emit(self, data)
