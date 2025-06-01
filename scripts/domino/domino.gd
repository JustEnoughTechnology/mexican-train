class_name Domino
extends ColorRect
## Visual representation of a domino tile
@onready var data: DominoData
@onready var back := $CenterContainer/DominoBack
@onready var front := $CenterContainer/DominoFront
@onready var container := $CenterContainer
@onready var orientation_label: Label = null

var imgpath = "res://assets/tiles/dominos/domino-%d-%d.svg"

@onready var old_modulate := modulate
@onready var is_highlighted := false

## Emitted when right mouse button is pressed on this domino
@warning_ignore("unused_signal")
signal mouse_right_pressed(p_domino: Domino)
## Emitted when a domino is dropped onto this one
signal domino_dropped(target: Domino, dropped: Domino)

func _ready() -> void:
	# Add orientation label overlay (for debugging orientation)
	if not has_node("OrientationLabel"):
		orientation_label = Label.new()
		orientation_label.name = "OrientationLabel"
		orientation_label.text = ""
		orientation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		orientation_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		orientation_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		orientation_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		orientation_label.anchor_left = 0.0
		orientation_label.anchor_top = 0.0
		orientation_label.anchor_right = 1.0
		orientation_label.anchor_bottom = 1.0
		orientation_label.position = Vector2(0, 0)
		orientation_label.custom_minimum_size = Vector2(82, 40)
		# Make the overlay invisible for now
		orientation_label.visible = false
		add_child(orientation_label)
	else:
		orientation_label = $OrientationLabel
	if GameState.DEBUG_SHOW_WARNINGS:
		print("[DOMINO] _ready: %s mouse_filter=%s" % [name, self.mouse_filter])
	self.mouse_filter = Control.MOUSE_FILTER_STOP
func _gui_input(event):
	if GameState.DEBUG_SHOW_WARNINGS:
		print("[DOMINO] _gui_input: %s event=%s" % [name, event])

	# Initialize data if it doesn't exist (when instantiated from scene)
	if data == null:
		data = DominoData.new(0, 0)  # Default to 0-0 domino

	# Ensure consistent sizes - the domino and all children should be 82x40, rounded to whole pixels
	var domino_size = Vector2(82, 40)
	if size != domino_size:
		call_deferred("set", "size", domino_size)

	# Set pivot points for proper rotation
	pivot_offset = size / 2

	# For now, give the domino a visible background for debugging
	# We'll make it semi-transparent gray so we can see the domino bounds
	self.color = Color(0.5, 0.5, 0.5, 0.3)  # Light gray, semi-transparent

	# Make sure container has the exact same size as the domino
	container.custom_minimum_size = domino_size
	container.set_deferred("size", domino_size)
	container.pivot_offset = domino_size / 2

	# Set up properties for front and back textures
	if front:
		# Set explicit size for front texture
		front.custom_minimum_size = domino_size
		front.size = domino_size
		front.pivot_offset = Vector2(round(41), round(20))  # Half of 82x40
		# Make sure front texture fits properly
		front.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		front.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# Ensure front is fully opaque
		front.modulate = Color(1, 1, 1, 1)

	if back:
		# Set explicit size for back texture
		back.custom_minimum_size = domino_size
		back.size = domino_size
		back.pivot_offset = Vector2(round(41), round(20))  # Half of 82x40
		# Make sure back texture fits properly
		back.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# Ensure back is fully opaque
		back.modulate = Color(1, 1, 1, 1)

	# Initialize face-up state and enforce mutual exclusivity of front and back visibility
	set_face_up(data.is_face_up)

	# Make sure all children have zero rotation relative to their parent
	container.rotation = 0
	if front:
		front.rotation = 0
	if back:
		back.rotation = 0

	# Do not connect gui_input signal manually; Godot already routes _gui_input automatically.
	# gui_input.connect(_gui_input)  # <-- REMOVE this line to avoid duplicate connection error


func _init(left := 0, right := 0) -> void:
	data = DominoData.new(left, right)

# Orientation constants (for convenience, mirror DominoData usage)



# TEMPORARY: Color-coding for orientation debugging
var ORIENTATION_COLORS = {
	DominoData.ORIENTATION_LARGEST_LEFT: Color(1, 0.4, 0.4, 0.35),    # Light Red, subtle
	DominoData.ORIENTATION_LARGEST_RIGHT: Color(0.4, 0.6, 1, 0.35),   # Light Blue, subtle
	DominoData.ORIENTATION_LARGEST_TOP: Color(0.4, 1, 0.4, 0.35),     # Light Green, subtle
	DominoData.ORIENTATION_LARGEST_BOTTOM: Color(1, 1, 0.4, 0.35),    # Light Yellow, subtle
}

func set_orientation(new_orientation: int) -> void:
	print("[DEBUG][%s] set_orientation called: %s (at %s)" % [name, str(new_orientation), str(Time.get_ticks_msec())])
	# Optionally print the call stack for deep debugging:
	# print_stack()
	data.orientation = new_orientation
	# Always start with default: largest on left, horizontal
	var left = data.dots.x
	var right = data.dots.y
	var rot = 0.0
	match data.orientation:
		DominoData.ORIENTATION_LARGEST_LEFT:
			# Largest on left, horizontal
			if left < right:
				var tmp = left
				left = right
				right = tmp
			rot = 0.0
		DominoData.ORIENTATION_LARGEST_RIGHT:
			# Largest on right, horizontal
			if left > right:
				var tmp = left
				left = right
				right = tmp
			rot = 180.0
		DominoData.ORIENTATION_LARGEST_TOP:
			# Largest on top, vertical
			if left < right:
				var tmp = left
				left = right
				right = tmp
			rot = -90.0
		DominoData.ORIENTATION_LARGEST_BOTTOM:
			# Largest on bottom, vertical
			if left > right:
				var tmp = left
				left = right
				right = tmp
			rot = 90.0
		_:
			rot = 0.0
	# Set the rotation only; do not call set_dots here to avoid recursion
	# (Orientation and dots must be set independently)
	# If you need to update the visual after changing dots, call set_orientation after set_dots externally.
	# (No call to set_dots here)

	# TEMPORARY: Overlay actual visual orientation letter for debugging
	var visual_orientation = "?"
	# After all swaps and rotation, determine where the largest value is visually
	if rot == 0.0:
		# Horizontal, largest on left
		visual_orientation = "L"
	elif rot == 180.0:
		# Horizontal, largest on right
		visual_orientation = "R"
	elif rot == -90.0:
		# Vertical, largest on top
		visual_orientation = "T"
	elif rot == 90.0:
		# Vertical, largest on bottom
		visual_orientation = "B"
	if orientation_label:
		orientation_label.text = visual_orientation
		orientation_label.visible = true
	# Remove or comment out color modulation for clarity
	modulate = old_modulate

	# Ensure the pivot is at the center for correct rotation
	pivot_offset = size / 2
	# Also ensure container and children have their pivots at center
	if container:
		container.pivot_offset = container.size / 2
	if front:
		front.pivot_offset = front.size / 2
	if back:
		back.pivot_offset = back.size / 2

	rotation_degrees = rot
	# Ensure children are not rotated
	if container:
		container.rotation = 0
	if front:
		front.rotation = 0
	if back:
		back.rotation = 0
	if GameState.DEBUG_SHOW_WARNINGS:
		print("[DOMINO] set_orientation: orientation=%d, dots=(%d,%d), rotation=%.1f, pivot_offset=%s" % [data.orientation, left, right, rot, str(pivot_offset)])


	
## Returns a preview control for drag and drop operations
## The preview shows either the front or back based on face up state
func get_preview() -> Control:
	# Create a simple preview that exactly matches the current domino
	var preview = ColorRect.new()
	preview.size = Vector2(82, 40) # Use consistent size of 82x40
	preview.color = color
	preview.modulate = modulate.lightened(0.2) # Slightly lighter to show it's a preview
	preview.z_index = 0 # Base at the bottom

	# Set pivot for proper rotation
	preview.pivot_offset = Vector2(41, 20) # Half of 82x40

	# Create a centered container like the original domino
	var preview_container = CenterContainer.new()
	preview_container.size = Vector2(82, 40) # Use consistent size
	preview_container.custom_minimum_size = Vector2(82, 40)
	preview_container.anchors_preset = Control.PRESET_FULL_RECT
	preview_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_container.z_index = 1 # Container in the middle
	preview.add_child(preview_container)

	# Create the appropriate visual element based on face up state
	var visual
	if data.is_face_up:
		visual = TextureRect.new()
		var texture_path = imgpath % [data.dots[0], data.dots[1]]
		visual.texture = load(texture_path)
		visual.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		visual = TextureRect.new()
		visual.texture = back.texture

	# Ensure proper size and alignment
	visual.custom_minimum_size = Vector2(size.x * 0.8, size.y * 0.8)
	visual.z_index = 2 # Visual elements on top
	preview_container.add_child(visual)

	# Apply the rotation to the preview itself, not to its children
	preview.rotation = rotation

	return preview

func _get_drag_data(_at_position: Vector2) -> Variant:
	if GameState.DEBUG_SHOW_WARNINGS:
		print("[DOMINO] _get_drag_data called for domino: %s" % name)
		print("Starting drag operation for domino: " + name)
		print("[DEBUG] Drag started: Domino %s, parent: %s" % [name, get_parent().name])
		print("[DEBUG] Domino state: dots=%s, face_up=%s, rotation=%s" % [data.dots, data.is_face_up, rotation_degrees])
		print("[DEBUG] Container rotation: %s" % [container.rotation_degrees])
		print("Drag started: Domino %s, parent: %s" % [name, get_parent().name])
		print("Domino state: dots=%s, face_up=%s, rotation=%s" % [data.dots, data.is_face_up, rotation_degrees])
		print("Container rotation: %s" % [container.rotation_degrees])

	var preview = get_preview()
	set_drag_preview(preview)

	# Store a reference to self in a property that won't be garbage collected
	get_tree().set_meta("current_drag_domino", self)

	# Return self as the drag data
	# Note: Godot's _drop_data will receive this return value
	return self
	
## Highlight or unhighlight the domino
func highlight(is_on: bool = true) -> void:
	modulate = old_modulate if !is_on else Color(0.9, 0.9, 0.9, 0.75)
	is_highlighted = is_on

## Set whether the domino is face up (showing dots) or face down
func set_face_up(is_on: bool = true) -> void:
	# Update the data model
	data.is_face_up = is_on
	
	# Keep the background visible for debugging (light gray, semi-transparent)
	# Don't make it fully transparent as it helps us see the domino bounds
	self.color = Color(0.5, 0.5, 0.5, 0.3)  # Light gray, semi-transparent
	
	# Strictly enforce mutual exclusivity of front and back visibility
	if front and back:
		if is_on:
			# Face up: front visible, back hidden
			front.visible = true
			back.visible = false
		else:
			# Face down: back visible, front hidden
			front.visible = false
			back.visible = true
	
	# Keep container rotation at 0
	if container:
		container.rotation = 0
	
	# Front and Back on top with proper sizing
	if front:
		front.z_index = 2
		front.rotation = 0
		front.custom_minimum_size = Vector2(82, 40)
	if back:
		back.z_index = 2
		back.rotation = 0
		back.custom_minimum_size = Vector2(82, 40)
	# Do not set size directly; layout will handle sizing
	container.custom_minimum_size = Vector2(82, 40)
	container.set_deferred("anchors_preset", Control.PRESET_FULL_RECT)
	
## Get the dots on this domino
func get_dots() -> Vector2i:
	return data.dots

## Set the dots on this domino
func set_dots(p_left: int, p_right: int) -> void:
	data.dots = Vector2i(max(p_left, p_right), min(p_left, p_right))
	if not front:
		push_error("[DOMINO] set_dots: 'front' is null for %s. You must add the domino to the scene tree before calling set_dots." % name)
		return
	var texture_path = imgpath % [data.dots[0], data.dots[1]]
	front.set_texture(load(texture_path))
	# Do not call set_orientation here to avoid recursion. Caller must update orientation if needed.

## Toggle between face up and face down
func toggle_dots() -> void:
	set_face_up(!data.is_face_up)

## Handle GUI input events

## Example handler for domino_dropped signal
## Connect this in parent containers if needed
func _on_domino_dropped(target: Domino, dropped: Domino) -> void:
	# This function can be used for testing or override in subclasses
	domino_dropped.emit(target, dropped)
