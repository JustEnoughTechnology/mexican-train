# Domino2D.gd
# This file has been moved to scenes/Domino_2_D/domino_2_d.tscn and scripts/domino_2_d/domino_2_d.gd
# Please use the new locations for all future work.

# New domino class: visual (half-domino scene-based) + mechanics (old Domino)
# Place in scripts/Domino_2_D/Domino2D.gd

extends Control
class_name Domino2D

## Visual representation: composed of two HalfDomino nodes
@onready var left_half: Node = $LeftHalf
@onready var right_half: Node = $RightHalf
@onready var container: CenterContainer = $CenterContainer
@onready var orientation_label: Label = $OrientationLabel if has_node("OrientationLabel") else null

## Mechanics/state (mirrors Domino)
var data: DominoData
var is_highlighted: bool = false
var show_orientation_label: bool = false:
	set(value):
		show_orientation_label = value
		if orientation_label:
			orientation_label.visible = value

## Signals (same as Domino)
@warning_ignore("unused_signal")
signal mouse_right_pressed(p_domino: Domino2D)
signal domino_dropped(target: Domino2D, dropped: Domino2D)

func _init(left := 0, right := 0) -> void:
	data = DominoData.new(left, right)

func _ready() -> void:
	# Set up halves visually
	_update_halves()
	# Set up orientation label
	if orientation_label:
		orientation_label.visible = show_orientation_label
	# Set up drag/drop, etc. as needed
	self.mouse_filter = Control.MOUSE_FILTER_STOP
	set_pivot_to_center()

func set_pivot_to_center() -> void:
	pivot_offset = size * 0.5

func set_dots(p_left: int, p_right: int) -> void:
	data.set_dots(p_left, p_right)
	_update_halves()

func set_face_up(is_on: bool = true) -> void:
	data.is_face_up = is_on
	_update_halves()

func set_orientation(orientation: int) -> void:
	data.orientation = orientation
	_update_halves()
	if orientation_label:
		orientation_label.visible = show_orientation_label
		_update_orientation_label_position(orientation)

func get_dots() -> Vector2i:
	return data.dots

func highlight(is_on: bool = true) -> void:
	is_highlighted = is_on
	# Optionally update visuals

func toggle_dots() -> void:
	set_face_up(!data.is_face_up)

func get_preview() -> Control:
	# Return a preview node (could instance a HalfDomino-based preview)
	var preview = Control.new()
	return preview

func _get_drag_data(_at_position: Vector2) -> Variant:
	# Implement drag logic as in Domino
	return self

func _update_halves() -> void:
	# Update left_half and right_half visuals based on data
	if left_half and right_half:
		left_half.set_dots(data.dots.x)
		right_half.set_dots(data.dots.y)
		left_half.set_face_up(data.is_face_up)
		right_half.set_face_up(data.is_face_up)
		# Set orientation, etc. as needed

func _update_orientation_label_position(orientation: int) -> void:
	# Position label as in Domino
	pass

func toggle_orientation_label(value: Variant = null) -> void:
	if value == null:
		show_orientation_label = !show_orientation_label
	else:
		show_orientation_label = value
	if orientation_label:
		orientation_label.visible = show_orientation_label

func _on_domino_dropped(target: Domino2D, dropped: Domino2D) -> void:
	domino_dropped.emit(target, dropped)
