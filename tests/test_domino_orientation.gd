extends Node

# Interactive orientation test for Domino

var domino: Domino
@onready var status_label: Label = $StatusLabel


func _ready() -> void:
	var DominoScene: PackedScene = preload("res://scenes/domino/domino.tscn")
	domino = DominoScene.instantiate() as Domino
	add_child(domino)
	domino.set_dots(5, 6)
	domino.set_face_up(true)
	domino.set_orientation(DominoData.ORIENTATION_LARGEST_TOP)
	domino.toggle_orientation_label(true)

	# Add a status label to show DominoData contents
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	status_label.position = Vector2(0, 10)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.size_flags_vertical = Control.SIZE_FILL
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	# Use anchors directly since Label does not have set_anchors_and_margins_preset
	status_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	status_label.custom_minimum_size = Vector2(0, 40)
	add_child(status_label)

	# (Removed orientation color key/legend; overlay is handled by domino.gd only)

	# Center the domino in the viewport
	call_deferred("_center_domino")
	call_deferred("_update_status")
	print("Use arrow keys to change orientation: Up=Top, Down=Bottom, Left=Left, Right=Right")

func _center_domino() -> void:
	if not domino:
		return
	var viewport_size: Vector2 = Vector2(get_viewport().size.x, get_viewport().size.y)
	var domino_size: Vector2 = Vector2(domino.size.x, domino.size.y)
	domino.position = viewport_size / 2 - domino_size / 2
	if status_label:
		status_label.size = Vector2(viewport_size.x, 40)

func _unhandled_input(event: InputEvent) -> void:
	if not domino:
		return
	var changed: bool = false
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP:
				domino.set_orientation(DominoData.ORIENTATION_LARGEST_TOP)
				changed = true
			KEY_DOWN:
				domino.set_orientation(DominoData.ORIENTATION_LARGEST_BOTTOM)
				changed = true
			KEY_LEFT:
				domino.set_orientation(DominoData.ORIENTATION_LARGEST_LEFT)
				changed = true
			KEY_RIGHT:
				domino.set_orientation(DominoData.ORIENTATION_LARGEST_RIGHT)
				changed = true
			KEY_O:
				domino.toggle_orientation_label()
				changed = true
	if changed:
		_update_status()


# Update the status label with DominoData contents, showing orientation as text
func _update_status() -> void:
	if not status_label or not domino:
		return
	var d: DominoData = domino.data
	var orientation_names: Array = [
		"LARGEST_LEFT",
		"LARGEST_RIGHT",
		"LARGEST_TOP",
		"LARGEST_BOTTOM"
	]
	var orientation_text: String = orientation_names[d.orientation] if d.orientation >= 0 and d.orientation < orientation_names.size() else str(d.orientation)
	status_label.text = "DominoData: dots=(%d,%d)\nface_up=%s\norientation=%s" % [d.dots.x, d.dots.y, str(d.is_face_up), orientation_text]
