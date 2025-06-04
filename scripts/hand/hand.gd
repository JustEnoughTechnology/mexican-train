class_name Hand
extends ColorRect

# --- Configurable max size percentages for Hand (match BoneYard) ---
@export var max_width_percent: float = 0.5 # 50% of parent/container width
@export var max_height_percent: float = 0.25 # 25% of parent/container height

# Signal emitted whenever the number of dominoes in the hand changes
signal domino_count_changed

# Hand-specific properties
@onready var my_player : Player
@onready var top_container : VBoxContainer = $hand_layout
@onready var domino_container : HFlowContainer = $hand_layout/domino_container
@onready var my_label : Label = $hand_layout/label
@onready var score: int = 0
@onready var is_drop_target_enabled := false

var d_scene : PackedScene = preload("res://scenes/domino/domino.tscn")

# Safe bg_color property for Hand, avoids errors if node is missing
@export var bg_color: Color:
	get:
		if has_node("hand_layout/label/bg"):
			return $"hand_layout/label/bg".color
		return Color(1,1,1,1)
	set(val):
		if has_node("hand_layout/label/bg"):
			$"hand_layout/label/bg".color = val

@export var label_text : String:
	set(p_value):
		$hand_layout/label.text = p_value
	get():
		return $hand_layout/label.text

func sort_ascending(domino1:Domino,domino2:Domino)->bool:
	return domino1.get_dots() < domino2.get_dots()

func sort_descending(domino1:Domino,domino2:Domino)->bool:
	return domino1.get_dots() > domino2.get_dots()

func sort(s:GameState.Sort):
	var d_array = domino_container.get_children()
	
	match s:
		GameState.Sort.SORT_ASCENDING:
			d_array.sort_custom(sort_ascending)
		GameState.Sort.SORT_DESCENDING:
			d_array.sort_custom(sort_descending)
		_:
			pass		
	
func add_domino(p_domino:Domino, p_face_up:bool=true) -> void:
	# Remove from previous parent if needed
	if is_instance_valid(p_domino) and p_domino.get_parent() != domino_container:
		var original_parent = p_domino.get_parent()
		if original_parent != null:
			original_parent.remove_child(p_domino)
		domino_container.add_child(p_domino)

	# Orient domino based on engine value if available
	_orient_domino_for_hand(p_domino)
	call_deferred("_update_hand_size_and_layout")
	p_domino.set_face_up(p_face_up)
	domino_count_changed.emit()
func remove_domino(p_domino:Domino) -> void:
	if domino_container.is_a_parent_of(p_domino):
		domino_container.remove_child(p_domino)
		call_deferred("_update_hand_size_and_layout")
		domino_count_changed.emit()

func _orient_domino_for_hand(p_domino: Domino) -> void:
	"""Orient domino so the side matching the engine value is on the left"""
	# Try to find a station in the scene to get the engine value
	var station = _find_station_in_scene()
	
	if station and station.has_engine():
		var engine_value = station.get_engine_value()
		var domino_dots = p_domino.get_dots()
		
		print("[HAND] Orienting domino %d-%d for engine value %d" % [domino_dots.x, domino_dots.y, engine_value])
		
		# Check if either side matches the engine value
		if domino_dots.x == engine_value:
			# Left side already matches - use LARGEST_LEFT orientation
			p_domino.set_orientation(DominoData.ORIENTATION_LARGEST_LEFT)
			print("[HAND] Set orientation LARGEST_LEFT (left side %d matches engine %d)" % [domino_dots.x, engine_value])
		elif domino_dots.y == engine_value:
			# Right side matches - swap values so engine value is on left
			p_domino.set_dots(domino_dots.y, domino_dots.x)  # Swap so engine value becomes left
			p_domino.set_orientation(DominoData.ORIENTATION_LARGEST_LEFT)
			print("[HAND] Swapped dots and set LARGEST_LEFT (right side %d now left matches engine %d)" % [domino_dots.y, engine_value])
		else:
			# No match - use default horizontal orientation
			p_domino.set_orientation(DominoData.ORIENTATION_LARGEST_LEFT)
			print("[HAND] No engine match - using default LARGEST_LEFT orientation")
	else:
		# No station or engine - use default horizontal orientation
		p_domino.set_orientation(DominoData.ORIENTATION_LARGEST_LEFT)
		print("[HAND] No engine found - using default LARGEST_LEFT orientation")

func _find_station_in_scene() -> Station:
	"""Find a Station node in the current scene"""
	# Look for a station starting from the scene root
	var scene_root = get_tree().current_scene
	return _find_station_recursive(scene_root)

func _find_station_recursive(node: Node) -> Station:
	"""Recursively search for a Station node"""
	if node is Station:
		return node
	
	for child in node.get_children():
		var result = _find_station_recursive(child)
		if result:
			return result
	
	return null
# Update hand size for left-to-right layout and extra space
func _update_hand_size_and_layout() -> void:
	var gap = 8
	# Reference size: parent container if present, else window
	var parent_control = get_parent() if get_parent() is Control else null
	var reference_size = parent_control.size if parent_control else get_window().size
	var max_width = round(reference_size.x * max_width_percent)
	var max_height = round(reference_size.y * max_height_percent)
	# Clamp max_width to parent size (never exceed parent, and always round)
	if parent_control:
		max_width = min(max_width, round(parent_control.size.x))

	if GameState.DEBUG_SHOW_WARNINGS:
		print("[HAND] _update_hand_size_and_layout: parent_control=%s, reference_size=%s, max_width=%s, max_height=%s" % [str(parent_control), str(reference_size), str(max_width), str(max_height)])

	# Wait for layout to update
	await get_tree().process_frame

	# --- Enforce anchors and offsets for pixel-perfect centering and clamping ---
	# This ensures the Hand node is always centered and never exceeds max_width_percent of its parent
	if self is Control and parent_control:
		self.anchor_left = 0.5
		self.anchor_right = 0.5
		self.offset_left = -max_width / 2
		self.offset_right = max_width / 2
		self.size_flags_horizontal = 0 # Remove fill/expand

	# Calculate height based on actual domino_container height after layout
	var vbox = top_container
	var label_height = vbox.get_child(0).size.y if vbox.get_child_count() > 0 else 0
	var domino_container_height = domino_container.size.y

	if GameState.DEBUG_SHOW_WARNINGS:
		print("[HAND] _update_hand_size_and_layout: label_height=%s, domino_container_height=%s, children=%d" % [str(label_height), str(domino_container_height), domino_container.get_child_count()])

	# Add label height and padding
	var padded_height = domino_container_height + label_height + 16

	# Clamp to window limits
	var _domino_height = 40
	var min_height = domino_container_height + label_height + 16

	# Hand width is always max_width (set by parent/container), only height shrinks/grows
	var final_width = max_width
	var final_height = min(max_height, padded_height)
	final_height = max(final_height, min_height)

	# Round to whole pixels
	final_width = round(final_width)
	final_height = round(final_height)

	# Set sizes for all containers (do not set self.size directly to avoid anchor warnings)
	self.custom_minimum_size = Vector2(final_width, final_height)

	if GameState.DEBUG_SHOW_WARNINGS:
		print("[HAND] _update_hand_size_and_layout: final_width=%s, final_height=%s, self.custom_minimum_size=%s" % [str(final_width), str(final_height), str(self.custom_minimum_size)])

	if domino_container:
		domino_container.custom_minimum_size = Vector2(final_width, 0)
		# Do not set .size directly
	if domino_container.has_method("add_constant_override"):
		domino_container.add_constant_override("separation", gap)

func get_domino(i:int)-> Domino:
	return domino_container.get_child(i)
	
func move_domino(p_domino:Domino,p_dest) ->void:
	p_domino.reparent(p_dest)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set player name using PlayerNameUtil
	var player_name_util = preload("res://scripts/util/player_name_util.gd")
	set_label_text(player_name_util.get_hand_label())
	# Only set custom_minimum_size, do not set size directly (avoids anchor warnings)
	var rounded_cms = Vector2(round(custom_minimum_size.x), round(custom_minimum_size.y))
	if custom_minimum_size != rounded_cms:
		custom_minimum_size = rounded_cms
	# Connect to child order changed signal to ensure score is updated
	if domino_container.has_signal("child_order_changed"):
		domino_container.child_order_changed.connect(_on_domino_container_child_order_changed)
	# Enable drop target for drag-and-drop
	enable_drop_target()
	# Connect to parent resized signal if possible
	var parent_control = get_parent() if get_parent() is Control else null
	if parent_control and parent_control.has_signal("resized"):
		parent_control.resized.connect(_on_parent_resized)
	# Debug log
	print("Hand initialized: ", name)
	call_deferred("_update_hand_size_and_layout")

	# Connect signals to monitor dominoes being added or reordered
	domino_container.child_entered_tree.connect(_on_domino_child_entered_tree)
	domino_container.child_order_changed.connect(_on_domino_child_order_changed)

func _on_domino_child_entered_tree(child):
	print("[DEBUG][HAND] Child entered tree: %s (at %s)" % [child.name, str(Time.get_ticks_msec())])

func _on_domino_child_order_changed():
	print("[DEBUG][HAND] Child order changed in domino_container (at %s)" % [str(Time.get_ticks_msec())])

# Called when the parent container is resized
func _on_parent_resized() -> void:
	call_deferred("_update_hand_size_and_layout")

# Returns the number of dominoes in the hand
func get_domino_count() -> int:
	return domino_container.get_child_count()

# Sets the label text for the hand
func set_label_text(p_text: String) -> void:
	my_label.text = p_text

# Gets the label text for the hand
func get_label_text() -> String:
	return my_label.text

func _on_domino_container_child_order_changed() -> void:
	score = 0
	for d:Domino in domino_container.get_children():
		score += d.get_dots().x + d.get_dots().y
	domino_count_changed.emit()

## Enable this hand as a drop target for dominoes
func enable_drop_target() -> void:
	is_drop_target_enabled = true

	# Ensure the hand can receive mouse events for drag and drop
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Also ensure child containers allow mouse events to pass through to the hand
	if top_container:
		top_container.mouse_filter = Control.MOUSE_FILTER_PASS
	if has_node("VBoxContainer/Label/bg"):
		var bg = $VBoxContainer/Label/bg
		bg.mouse_filter = Control.MOUSE_FILTER_PASS
		bg.color = bg.color.lightened(0.2)
	if domino_container:
		domino_container.mouse_filter = Control.MOUSE_FILTER_PASS

	if GameState.DEBUG_SHOW_WARNINGS:
		print("Hand set as drop target with mouse_filter: " + str(mouse_filter))

## Called to test if this control can accept the specified data.
## When dropping is attempted, this will be called first and must return true for _drop_data to be called.
func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	# Only accept Domino objects, and only if not already in this hand
	if !is_drop_target_enabled:
		return false
	if data is Domino:
		var drag_domino = data
		if get_tree().has_meta("current_drag_domino"):
			drag_domino = get_tree().get_meta("current_drag_domino")
		if drag_domino.get_parent() == domino_container:
			return false
		return true
	return false

## Called when data is dropped in this control.
func _drop_data(_position: Vector2, data: Variant) -> void:
	if is_drop_target_enabled and data is Domino:
		var drag_domino = data
		if get_tree().has_meta("current_drag_domino"):
			drag_domino = get_tree().get_meta("current_drag_domino")

		# Always set orientation to LARGEST_TOP as the very first thing
		drag_domino.set_orientation(DominoData.ORIENTATION_LARGEST_TOP)

		# Only move if not already in this hand
		if drag_domino.get_parent() != domino_container:
			var original_parent = drag_domino.get_parent()
			if original_parent:
				original_parent.remove_child(drag_domino)
			# Use add_domino to ensure correct orientation and layout
			add_domino(drag_domino, true)
			if get_tree().has_meta("current_drag_domino"):
				get_tree().remove_meta("current_drag_domino")
			if get_tree().has_meta("current_drag_source"):
				get_tree().remove_meta("current_drag_source")
			print("Domino moved to hand successfully")
