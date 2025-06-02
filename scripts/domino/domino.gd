class_name Domino
extends ColorRect
## Visual representation of a domino tile
var data: DominoData
@onready var back: TextureRect = $CenterContainer/DominoBack
@onready var front: TextureRect = $CenterContainer/DominoFront
@onready var container: CenterContainer = $CenterContainer
@onready var orientation_label: Label = null

var imgpath: String = "res://assets/tiles/dominos/domino-%d-%d.svg"
var imgpath_oriented: String = "res://assets/tiles/dominos/domino-%d-%d_%s.svg"

@onready var old_modulate: Color = modulate
@onready var is_highlighted: bool = false

## Emitted when right mouse button is pressed on this domino
@warning_ignore("unused_signal")
signal mouse_right_pressed(p_domino: Domino)
## Emitted when a domino is dropped onto this one
signal domino_dropped(target: Domino, dropped: Domino)


func _ready() -> void:
	# Ensure the front texture is set on scene start using current data
	set_dots(data.dots.x, data.dots.y)
	# Use the OrientationLabel node from the scene if present
	orientation_label = $OrientationLabel if has_node("OrientationLabel") else null

	self.mouse_filter = Control.MOUSE_FILTER_STOP

	# Set pivot to center for proper rotation
	set_pivot_to_center()


# Helper to set pivot to center
func set_pivot_to_center() -> void:
	# Use current size, or default if not yet set
	var center = size * 0.5
	pivot_offset = center




func _init(left := 0, right := 0) -> void:
	print("init:L%d R%d"%[left,right])
	data = DominoData.new(left, right)

# Orientation constants (for convenience, mirror DominoData usage)



# TEMPORARY: Color-coding for orientation debugging
var ORIENTATION_COLORS = {
	DominoData.ORIENTATION_LARGEST_LEFT: Color(1, 0.4, 0.4, 0.35),    # Light Red, subtle
	DominoData.ORIENTATION_LARGEST_RIGHT: Color(0.4, 0.6, 1, 0.35),   # Light Blue, subtle
	DominoData.ORIENTATION_LARGEST_TOP: Color(0.4, 1, 0.4, 0.35),     # Light Green, subtle
	DominoData.ORIENTATION_LARGEST_BOTTOM: Color(1, 1, 0.4, 0.35),    # Light Yellow, subtle
}

## Orientation label overlay contract:
# Only external scripts (such as test scripts) should toggle the orientation label overlay.
# The domino script itself never toggles the orientation label automatically, including when added to the hand.
# To show or hide the overlay, use the `show_orientation_label` property or call `toggle_orientation_label()` from outside this script.
var show_orientation_label: bool = false:
	set(value):
		show_orientation_label = value
		if orientation_label:
			orientation_label.visible = value


	
## Returns a preview control for drag and drop operations
## The preview shows either the front or back based on face up state
func get_preview() -> Control:
	# Create a simple preview that exactly matches the current domino
	var preview: ColorRect = ColorRect.new()
	
	# Use size based on current orientation
	var preview_size = Vector2(82, 40)  # Default horizontal
	if data.orientation == DominoData.ORIENTATION_LARGEST_TOP or data.orientation == DominoData.ORIENTATION_LARGEST_BOTTOM:
		preview_size = Vector2(40, 82)  # Vertical orientations
	
	preview.size = preview_size
	preview.color = color
	preview.modulate = modulate.lightened(0.2) # Slightly lighter to show it's a preview
	preview.z_index = 0 # Base at the bottom

	# Set pivot for proper rotation
	preview.pivot_offset = preview_size * 0.5

	# Create a centered container like the original domino
	var preview_container: CenterContainer = CenterContainer.new()
	preview_container.size = preview_size
	preview_container.custom_minimum_size = preview_size
	preview_container.anchors_preset = Control.PRESET_FULL_RECT
	preview_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_container.z_index = 1 # Container in the middle
	preview.add_child(preview_container)

	# Create the appropriate visual element based on face up state
	var visual: TextureRect
	if data.is_face_up:
		visual = TextureRect.new()
		var texture_path: String = get_texture_path_for_orientation()
		visual.texture = load(texture_path)
		visual.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		visual = TextureRect.new()
		visual.texture = back.texture

	# Ensure proper size and alignment
	visual.custom_minimum_size = Vector2(preview_size.x * 0.8, preview_size.y * 0.8)
	visual.z_index = 2 # Visual elements on top
	preview_container.add_child(visual)

	# No rotation needed - using pre-rotated textures
	# preview.rotation = rotation

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
	# Optionally implement highlight by changing border or outline, but do not use modulate
	is_highlighted = is_on

## Set whether the domino is face up (showing dots) or face down
func set_face_up(is_on: bool = true) -> void:
	# Update the data model
	data.is_face_up = is_on
	
	# Do not use modulate or color for face switching; only use visible property
	
	# Strictly enforce mutual exclusivity of front and back visibility
	if front and back:
		if is_on:
			front.visible = true
			back.visible = false
		else:
			front.visible = false
			back.visible = true
	
	# DO NOT reset rotations here - preserve orientation settings
	# The rotation should only be controlled by set_orientation()
	
	# Front and Back on top with proper sizing based on current orientation
	var current_size = Vector2(82, 40)  # Default horizontal
	if data.orientation == DominoData.ORIENTATION_LARGEST_TOP or data.orientation == DominoData.ORIENTATION_LARGEST_BOTTOM:
		current_size = Vector2(40, 82)  # Vertical orientations
	
	if front:
		front.z_index = 2
		# DO NOT reset front.rotation - preserve orientation
		front.custom_minimum_size = current_size
	if back:
		back.z_index = 2
		# DO NOT reset back.rotation - preserve orientation  
		back.custom_minimum_size = current_size
	# Do not set size directly; layout will handle sizing
	container.custom_minimum_size = current_size
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
	var texture_path: String = imgpath % [data.dots[0], data.dots[1]]
	front.set_texture(load(texture_path))
	# Do not call set_orientation here to avoid recursion. Caller must update orientation if needed.

## Get the correct texture path based on current orientation
func get_texture_path_for_orientation() -> String:
	var base_path = imgpath % [data.dots[0], data.dots[1]]
	
	# If no orientation is set, use base texture
	if data.orientation == 0:
		print("[DOMINO] Using base texture: %s" % base_path)
		return base_path
	
	# Use pre-rotated textures based on orientation
	var orientation_suffix = ""
	match data.orientation:
		DominoData.ORIENTATION_LARGEST_LEFT:
			orientation_suffix = "_left"
		DominoData.ORIENTATION_LARGEST_RIGHT:
			orientation_suffix = "_right"
		DominoData.ORIENTATION_LARGEST_TOP:
			orientation_suffix = "_top"
		DominoData.ORIENTATION_LARGEST_BOTTOM:
			orientation_suffix = "_bottom"
		_:
			# Fallback to base texture for invalid orientations
			print("[DOMINO] Invalid orientation %s, using base texture: %s" % [data.orientation, base_path])
			return base_path
	
	# Build oriented texture path
	var base_name = base_path.get_basename()  # removes .svg
	var oriented_path = base_name + orientation_suffix + ".svg"
	print("[DOMINO] Using oriented texture: %s (orientation: %s)" % [oriented_path, data.orientation])
	return oriented_path

## Toggle between face up and face down
func toggle_dots() -> void:
	set_face_up(!data.is_face_up)

## Handle GUI input events

## Example handler for domino_dropped signal
## Connect this in parent containers if needed
func _on_domino_dropped(target: Domino, dropped: Domino) -> void:
	# This function can be used for testing or override in subclasses
	domino_dropped.emit(target, dropped)

# Set the orientation of the domino visually and logically
func set_orientation(orientation: int) -> void:
	# Set the orientation in the data model
	data.orientation = orientation

	# Reset all rotations
	rotation = 0
	if container:
		container.rotation = 0
	if front:
		front.rotation = 0
	if back:
		back.rotation = 0

	# Always set pivot to center for correct rotation
	set_pivot_to_center()

	# Set the rotation and dot order based on orientation
	# Note: The domino images are horizontal by default (larger value on left)
	match orientation:
		DominoData.ORIENTATION_LARGEST_LEFT:
			rotation_degrees = 0  # No rotation needed, largest on left naturally
			if data.dots.x >= data.dots.y:
				set_dots(data.dots.x, data.dots.y)
			else:
				set_dots(data.dots.y, data.dots.x)
		DominoData.ORIENTATION_LARGEST_RIGHT:
			rotation_degrees = 180  # Flip 180 to put largest on right
			if data.dots.x >= data.dots.y:
				set_dots(data.dots.x, data.dots.y)
			else:
				set_dots(data.dots.y, data.dots.x)
		DominoData.ORIENTATION_LARGEST_TOP:
			rotation_degrees = 90  # Rotate clockwise to put largest at top
			if data.dots.x >= data.dots.y:
				set_dots(data.dots.x, data.dots.y)
			else:
				set_dots(data.dots.y, data.dots.x)
		DominoData.ORIENTATION_LARGEST_BOTTOM:
			rotation_degrees = -90  # Rotate counter-clockwise to put largest at bottom
			if data.dots.x >= data.dots.y:
				set_dots(data.dots.x, data.dots.y)
			else:
				set_dots(data.dots.y, data.dots.x)
		_:
			push_error("[DOMINO] set_orientation: Invalid orientation value: %s" % orientation)

	# Update the orientation label overlay if present
	if orientation_label:
		# Map orientation to human-friendly label
		var orientation_map = {
			DominoData.ORIENTATION_LARGEST_LEFT: "L",
			DominoData.ORIENTATION_LARGEST_RIGHT: "R",
			DominoData.ORIENTATION_LARGEST_TOP: "T",
			DominoData.ORIENTATION_LARGEST_BOTTOM: "B"
		}
		if orientation_map.has(orientation):
			orientation_label.text = orientation_map[orientation]
		else:
			orientation_label.text = "?"
		orientation_label.visible = show_orientation_label

## Helper method to toggle the orientation label overlay
# Only call this from external scripts (e.g., test scripts) to control the overlay.
func toggle_orientation_label(value: Variant = null) -> void:
	if value == null:
		show_orientation_label = !show_orientation_label
	else:
		show_orientation_label = value
