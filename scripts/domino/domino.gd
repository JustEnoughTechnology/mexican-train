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
	# Set proper initial size based on orientation
	var current_size = Vector2(82, 40)  # Default horizontal
	if data.orientation == DominoData.ORIENTATION_LARGEST_TOP or data.orientation == DominoData.ORIENTATION_LARGEST_BOTTOM:
		current_size = Vector2(40, 82)  # Vertical orientations
	
	# Set initial domino size
	custom_minimum_size = current_size
	size = current_size
	
	# Ensure the front texture is set on scene start using current data
	set_dots(data.dots.x, data.dots.y)
	
	# Ensure the back texture is also set with proper orientation
	if back:
		var back_texture_path = get_back_texture_path_for_orientation()
		back.set_texture(load(back_texture_path))
	
	# Ensure container is properly sized
	if container:
		container.custom_minimum_size = current_size
		# Don't set size directly, let the container manage its own size
	
	# Configure TextureRect nodes for proper display
	if front:
		front.custom_minimum_size = current_size
		front.size = current_size
		front.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		front.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if back:
		back.custom_minimum_size = current_size
		back.size = current_size
		back.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
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
	Logger.log_debug(Logger.LogArea.GAME, "Domino initialized: L%d R%d" % [left, right])
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
		var back_texture_path: String = get_back_texture_path_for_orientation()
		visual.texture = load(back_texture_path)
		visual.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Ensure proper size and alignment
	visual.custom_minimum_size = Vector2(preview_size.x * 0.8, preview_size.y * 0.8)
	visual.z_index = 2 # Visual elements on top
	preview_container.add_child(visual)

	# No rotation needed - using pre-rotated textures
	# preview.rotation = rotation

	return preview

func _get_drag_data(_at_position: Vector2) -> Variant:
	# Determine the source type by checking parent hierarchy
	var source_type = _get_source_type()
	# Block dragging from train and station (engine)
	if source_type == "train" or source_type == "station":
		if GameConfig.DEBUG_SHOW_WARNINGS:
			Logger.log_warning(Logger.LogArea.GAME, "Drag blocked: Cannot drag from %s" % source_type)
		return null
	
	if GameConfig.DEBUG_SHOW_WARNINGS:
		Logger.log_debug(Logger.LogArea.GAME, "_get_drag_data called for domino: %s from %s" % [name, source_type])
		Logger.log_debug(Logger.LogArea.GAME, "Starting drag operation for domino: " + name)
		Logger.log_debug(Logger.LogArea.GAME, "Drag started: Domino %s, parent: %s, source: %s" % [name, get_parent().name, source_type])
		Logger.log_debug(Logger.LogArea.GAME, "Domino state: dots=%s, face_up=%s, rotation=%s" % [data.dots, data.is_face_up, rotation_degrees])

	var preview = get_preview()
	set_drag_preview(preview)

	# Store a reference to self and source type in metadata
	get_tree().set_meta("current_drag_domino", self)
	get_tree().set_meta("current_drag_source", source_type)

	# Return self as the drag data
	return self

## Determine the source type by checking the parent hierarchy
func _get_source_type() -> String:
	var current_node = get_parent()
	while current_node:
		# Check if we're in a boneyard
		if current_node.has_method("is_boneyard"):
			return "boneyard"
		# Check if we're in a hand
		if current_node is Hand:
			return "hand"
		# Check if we're in a train
		if current_node.name.to_lower().contains("train") or current_node.has_method("get_open_end"):
			return "train"
		# Check if we're in a station (engine)
		if current_node.name.to_lower().contains("station") or current_node.has_method("can_place_engine"):
			return "station"
		current_node = current_node.get_parent()
	
	return "unknown"
	
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
			# Ensure back texture uses the oriented version
			var back_texture_path = get_back_texture_path_for_orientation()
			back.set_texture(load(back_texture_path))
	
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
		front.size = current_size
		front.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		front.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if back:
		back.z_index = 2
		# DO NOT reset back.rotation - preserve orientation  
		back.custom_minimum_size = current_size
		back.size = current_size
		back.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Update container size to match orientation
	container.custom_minimum_size = current_size
	# Don't set container size directly, let it manage itself
	
## Get the dots on this domino
func get_dots() -> Vector2i:
	return data.dots

## Set the dots on this domino
func set_dots(p_left: int, p_right: int) -> void:
	# Use the DominoData.set_dots() method which preserves order as (x,y)
	data.set_dots(p_left, p_right)
	if not front:
		Logger.log_error(Logger.LogArea.GAME, "[DOMINO] set_dots: 'front' is null for %s. You must add the domino to the scene tree before calling set_dots." % name)
		return
	# Always use oriented texture path, never bare domino
	var texture_path: String = get_texture_path_for_orientation()
	front.set_texture(load(texture_path))
	# Do not call set_orientation here to avoid recursion. Caller must update orientation if needed.

## Get the correct texture path based on current orientation
func get_texture_path_for_orientation() -> String:
	# Always use oriented textures - never bare domino
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
			# Default to left orientation for invalid orientations
			Logger.log_warning(Logger.LogArea.GAME, "Invalid orientation %s, defaulting to left" % data.orientation)
			orientation_suffix = "_left"
	
	# Texture files are always named domino-L-R_orientation.svg where L >= R
	# So we need to ensure we use max(x,y) and min(x,y) for the filename
	var larger_dots = max(data.dots.x, data.dots.y)
	var smaller_dots = min(data.dots.x, data.dots.y)
	
	# Build oriented texture path using imgpath_oriented format with larger-smaller ordering
	var oriented_path = imgpath_oriented % [larger_dots, smaller_dots, orientation_suffix.substr(1)]  # Remove leading underscore
		# Check if the file exists
	if not ResourceLoader.exists(oriented_path):
		Logger.log_error(Logger.LogArea.GAME, "Texture file does not exist: %s" % oriented_path)
		# Use a fallback texture that actually exists
		var fallback_path = "res://assets/tiles/dominos/domino-0-0_left.svg"
		return fallback_path
	
	return oriented_path

## Get the correct back texture path based on current orientation
func get_back_texture_path_for_orientation() -> String:
	# Always use oriented back textures
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
			# Default to left orientation for invalid orientations
			Logger.log_warning(Logger.LogArea.GAME, "Invalid back orientation %s, defaulting to left" % data.orientation)
			orientation_suffix = "_left"
	
	# Build oriented back texture path
	var oriented_back_path = "res://assets/tiles/dominos/domino-back%s.svg" % orientation_suffix
	
	# Check if the file exists
	if not ResourceLoader.exists(oriented_back_path):
		Logger.log_error(Logger.LogArea.GAME, "Back texture file does not exist: %s" % oriented_back_path)
		# Use a fallback texture that actually exists - just use the front texture
		var fallback_path = "res://assets/tiles/dominos/domino-0-0_left.svg"
		return fallback_path
	
	return oriented_back_path
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

	# No container rotation needed - we use pre-oriented SVG textures
	# The oriented textures handle the visual rotation
	
	# Set the correct dots order (largest first)
	if data.dots.x >= data.dots.y:
		set_dots(data.dots.x, data.dots.y)
	else:
		set_dots(data.dots.y, data.dots.x)

	# Set the correct SVG for the orientation
	if front:
		var texture_path = get_texture_path_for_orientation()
		front.set_texture(load(texture_path))
	
	# Set the correct back texture for the orientation
	if back:
		var back_texture_path = get_back_texture_path_for_orientation()
		back.set_texture(load(back_texture_path))

	# Set the correct size for horizontal/vertical orientations
	# Since we use pre-oriented textures, adjust the container size to match
	var current_size = Vector2(82, 40)  # Default horizontal
	if orientation == DominoData.ORIENTATION_LARGEST_TOP or orientation == DominoData.ORIENTATION_LARGEST_BOTTOM:
		current_size = Vector2(40, 82)  # Vertical orientations need swapped dimensions
	
	# Update the domino's own size to match the orientation
	custom_minimum_size = current_size
	size = current_size
	
	# Update container size - only set custom_minimum_size, let it expand naturally
	if container:
		container.custom_minimum_size = current_size
		# Don't set size directly, let the container manage its own size
	
	# Update TextureRect nodes - use proper sizing for display
	if front:
		# Set the TextureRect to fill the container
		front.custom_minimum_size = current_size
		front.size = current_size
		# Use expand mode that fills the available space
		front.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		front.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if back:
		# Set the TextureRect to fill the container
		back.custom_minimum_size = current_size
		back.size = current_size
		# Use expand mode that fills the available space
		back.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Update the orientation label overlay if present
	if orientation_label:
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
		
		# Position and rotate the label based on orientation
		_update_orientation_label_position(orientation)

## Helper method to toggle the orientation label overlay
# Only call this from external scripts (e.g., test scripts) to control the overlay.
func toggle_orientation_label(value: Variant = null) -> void:
	if value == null:
		show_orientation_label = !show_orientation_label
	else:
		show_orientation_label = value
	
	if orientation_label:
		orientation_label.visible = show_orientation_label

## Update the orientation label position and rotation based on domino orientation
func _update_orientation_label_position(orientation: int) -> void:
	if not orientation_label:
		return
	
	# Reset to default anchors and offsets
	orientation_label.rotation = 0
	
	# Base label size
	var label_size = Vector2(24, 24)
	var margin = 4
	
	match orientation:
		DominoData.ORIENTATION_LARGEST_LEFT:
			# Horizontal domino with largest on left - label at top-right
			orientation_label.anchor_left = 1.0
			orientation_label.anchor_right = 1.0
			orientation_label.anchor_top = 0.0
			orientation_label.anchor_bottom = 0.0
			orientation_label.offset_left = -label_size.x - margin
			orientation_label.offset_right = -margin
			orientation_label.offset_top = margin
			orientation_label.offset_bottom = label_size.y + margin
			
		DominoData.ORIENTATION_LARGEST_RIGHT:
			# Horizontal domino with largest on right - label at top-left
			orientation_label.anchor_left = 0.0
			orientation_label.anchor_right = 0.0
			orientation_label.anchor_top = 0.0
			orientation_label.anchor_bottom = 0.0
			orientation_label.offset_left = margin
			orientation_label.offset_right = label_size.x + margin
			orientation_label.offset_top = margin
			orientation_label.offset_bottom = label_size.y + margin
			
		DominoData.ORIENTATION_LARGEST_TOP:
			# Vertical domino with largest on top - label at bottom-right
			orientation_label.anchor_left = 1.0
			orientation_label.anchor_right = 1.0
			orientation_label.anchor_top = 1.0
			orientation_label.anchor_bottom = 1.0
			orientation_label.offset_left = -label_size.x - margin
			orientation_label.offset_right = -margin
			orientation_label.offset_top = -label_size.y - margin
			orientation_label.offset_bottom = -margin
			
		DominoData.ORIENTATION_LARGEST_BOTTOM:
			# Vertical domino with largest on bottom - label at top-right
			orientation_label.anchor_left = 1.0
			orientation_label.anchor_right = 1.0
			orientation_label.anchor_top = 0.0
			orientation_label.anchor_bottom = 0.0
			orientation_label.offset_left = -label_size.x - margin
			orientation_label.offset_right = -margin
			orientation_label.offset_top = margin
			orientation_label.offset_bottom = label_size.y + margin
