class_name Train extends ColorRect

# Signals
signal domino_added

# Display mode for the train
@export var show_single_domino: bool = false  # When true, shows only the most recent domino

@onready var my_player : Player
@onready var top_container :HBoxContainer = $TopContainer
@onready var domino_container : HBoxContainer = $TopContainer/bg/DominoContainer
@onready var my_label :Label =$TopContainer/bg/Label

@export var bg_color:Color:
	get: 
		return $TopContainer/bg.color
	set(val):
		$TopContainer/bg.color = val
		
var d_scene : PackedScene = preload("res://scenes/domino/domino.tscn")

@export var label_text : String  :
	set(p_value):
		$TopContainer/bg/Label.text = p_value
	get():
		return $TopContainer/bg/Label.text

func set_background_color(bg_color_value: Color) -> void:
	"""Set the background color of the train for visibility"""
	bg_color = bg_color_value
	if has_node("TopContainer/bg"):
		$TopContainer/bg.color = bg_color_value

func set_single_domino_mode(enabled: bool) -> void:
	"""Enable or disable single domino display mode"""
	show_single_domino = enabled
	if enabled:
		# If enabling single mode and we have multiple dominoes, keep only the last one
		var children = domino_container.get_children()
		var dominoes = []
		for child in children:
			if child is Domino:
				dominoes.append(child)
		
		if dominoes.size() > 1:
			# Keep only the last domino (most recently added)
			for i in range(dominoes.size() - 1):
				domino_container.remove_child(dominoes[i])
				dominoes[i].queue_free()
	
	_update_train_size()

func get_domino_count() -> int:
	return domino_container.get_child_count()
	
func set_label_text(p_text:String):
	if my_label:
		my_label.text = p_text
	else:
		push_warning("Train: my_label is null, cannot set label text.")

func get_label_text()->String:
	return self.my_label.text if my_label else ""
	
func sort_ascending(domino1:Domino,domino2:Domino)->bool:
	return domino1.get_dots() < domino2.get_dots()

func sort_descending(domino1:Domino,domino2:Domino)->bool:
	return domino1.get_dots() > domino2.get_dots()

func sort(s:GameConfig.Sort):
	var d_array = domino_container.get_children()
	
	match s:
		GameConfig.Sort.SORT_ASCENDING:
			d_array.sort_custom(sort_ascending)
		GameConfig.Sort.SORT_DESCENDING:
			d_array.sort_custom(sort_descending)
		_:
			pass		
	
func add_domino(p_domino:Domino, p_face_up:bool=true) -> void:
	# Force horizontal orientation for all dominoes in train
	var domino_dots = p_domino.get_dots()
	if p_domino.data.orientation == DominoData.ORIENTATION_LARGEST_TOP or p_domino.data.orientation == DominoData.ORIENTATION_LARGEST_BOTTOM:
		print("WARNING: Domino %s has vertical orientation %d, forcing to horizontal" % [p_domino.name, p_domino.data.orientation])
		# Force to horizontal based on which side has more dots
		if domino_dots.x >= domino_dots.y:
			p_domino.set_orientation(DominoData.ORIENTATION_LARGEST_LEFT)
			print("Forced to LARGEST_LEFT")
		else:
			p_domino.set_orientation(DominoData.ORIENTATION_LARGEST_RIGHT)
			print("Forced to LARGEST_RIGHT")
	
	# If in single domino mode, remove all existing dominoes first
	if show_single_domino:
		for child in domino_container.get_children():
			if child is Domino:
				domino_container.remove_child(child)
				child.queue_free()
	
	# Add domino to the RIGHT side of the container (normal add_child behavior)
	domino_container.add_child(p_domino)
	p_domino.set_face_up(p_face_up)
	
	# Update train sizing
	_update_train_size()
	
	print("Added domino to train (right side). Total dominoes: ", get_domino_count())

func _update_train_size() -> void:
	# Calculate required size based on dominoes
	var domino_count = get_domino_count()
	if domino_count == 0:
		domino_container.custom_minimum_size = Vector2(130, 40)
		return
	
	# Each domino is 82x40 when horizontal + spacing
	var domino_width = 82
	var spacing = 4  # HBoxContainer separation
	var total_width = (domino_width * domino_count) + (spacing * (domino_count - 1))
	
	domino_container.custom_minimum_size = Vector2(max(130, total_width), 40)

func _can_drop_data(_position: Vector2, data) -> bool:
	# Only accept Domino instances
	if not data is Domino:
		return false
	
	# Check source type from metadata
	var source_type = ""
	if get_tree().has_meta("current_drag_source"):
		source_type = get_tree().get_meta("current_drag_source")
	
	# Only allow drops from hand
	if source_type != "hand":
		if GameConfig.DEBUG_SHOW_WARNINGS:
			print("Train _can_drop_data: Rejected - source is '%s', only 'hand' allowed" % source_type)
		return false
	
	var drag_domino = data
	# Get the domino from metadata if available
	if get_tree().has_meta("current_drag_domino"):
		drag_domino = get_tree().get_meta("current_drag_domino")
	
	if GameConfig.DEBUG_SHOW_WARNINGS:
		print("Train _can_drop_data: source_type = %s (allowed)" % source_type)
	
	var incoming_dots = drag_domino.get_dots()
	
	# If train is empty, check against station engine value
	if get_domino_count() == 0:
		# Look for a station in the scene to get the engine value
		var station = find_station_in_scene()
		if station and station.has_engine():
			var required_engine_value = station.get_engine_value()
			
			print("\n=== EMPTY TRAIN CONNECTION CHECK ===")
			print("Station engine value: %d" % required_engine_value)
			print("Incoming domino: %d-%d" % [incoming_dots.x, incoming_dots.y])
			print("Checking if %d or %d matches required %d" % [incoming_dots.x, incoming_dots.y, required_engine_value])
			
			var can_connect_to_station = (incoming_dots.x == required_engine_value or incoming_dots.y == required_engine_value)
			print("Can connect to station: %s" % str(can_connect_to_station))
			print("===================================\n")
			return can_connect_to_station
		else:
			print("No station found or station has no engine - train cannot accept dominoes yet")
			return false
	
	# Get the rightmost domino and its right-side dot count
	var last_domino = get_last_domino()
	if not last_domino:
		return true  # Fallback if we can't get last domino
	
	# Get the correct right-side value based on domino orientation
	var required_dots = _get_domino_right_side_value(last_domino)
	
	# DEBUG: Print detailed connection info
	print("\n=== DOMINO CONNECTION CHECK ===")
	print("Checking domino: %s" % drag_domino.name)
	print("  Original dots: %d-%d (x=%d, y=%d)" % [incoming_dots.x, incoming_dots.y, incoming_dots.x, incoming_dots.y])
	print("  Original orientation: %d (%s)" % [drag_domino.data.orientation, _orientation_to_string(drag_domino.data.orientation)])
	print("Last domino: %d-%d, orientation: %d (%s)" % [last_domino.get_dots().x, last_domino.get_dots().y, last_domino.data.orientation, _orientation_to_string(last_domino.data.orientation)])
	print("Last domino right side value: %d" % required_dots)
	print("Checking if %d or %d matches required %d" % [incoming_dots.x, incoming_dots.y, required_dots])
	
	# Check if either side of the incoming domino matches the required connection
	var can_connect = (incoming_dots.x == required_dots or incoming_dots.y == required_dots)
	
	print("Can connect: %s" % str(can_connect))
	print("===============================")
	
	if not can_connect:
		print("Cannot drop domino %s: needs %d dots to connect, but has %d-%d" % [
			drag_domino.name, required_dots, incoming_dots.x, incoming_dots.y])
	
	return can_connect

func _drop_data(_position: Vector2, data) -> void:
	if data is Domino:
		var drag_domino = data
		# Get the domino from metadata if available (matching Hand implementation)
		if get_tree().has_meta("current_drag_domino"):
			drag_domino = get_tree().get_meta("current_drag_domino")
		
		# ====== DEBUG: ORIGINAL DOMINO STATE ======
		print("\n========== DOMINO DROP DEBUG START ==========")
		print("ORIGINAL DOMINO STATE (before any changes):")
		print("  Name: %s" % drag_domino.name)
		print("  Dots: %d-%d (x=%d, y=%d)" % [drag_domino.get_dots().x, drag_domino.get_dots().y, drag_domino.get_dots().x, drag_domino.get_dots().y])
		print("  Orientation: %d (%s)" % [drag_domino.data.orientation, _orientation_to_string(drag_domino.data.orientation)])
		
		# Get expected connection info
		var required_dots = -1
		if get_domino_count() > 0:
			var last_domino = get_last_domino()
			required_dots = _get_domino_right_side_value(last_domino)
			print("  Must connect to: %d dots (from last domino)" % required_dots)
		else:
			print("  First domino - no connection required")
		print("=============================================")
		
		# Remove from original parent before adding to train
		if drag_domino.get_parent():
			drag_domino.get_parent().remove_child(drag_domino)
		
		# Auto-orient the domino for proper connection
		_orient_domino_for_connection(drag_domino)
		
		# ====== DEBUG: AFTER ORIENTATION ======
		print("\nAFTER ORIENTATION (before adding to train):")
		print("  Name: %s" % drag_domino.name)
		print("  Dots: %d-%d (x=%d, y=%d)" % [drag_domino.get_dots().x, drag_domino.get_dots().y, drag_domino.get_dots().x, drag_domino.get_dots().y])
		print("  Orientation: %d (%s)" % [drag_domino.data.orientation, _orientation_to_string(drag_domino.data.orientation)])
		print("==========================================")
		
		# Add to train with horizontal orientation
		add_domino(drag_domino)
		
		# Emit signal that a domino was added
		domino_added.emit()
		
		# ====== DEBUG: FINAL DOMINO STATE ======
		print("\nFINAL DOMINO STATE (after orientation and add):")
		print("  Name: %s" % drag_domino.name)
		print("  Dots: %d-%d (x=%d, y=%d)" % [drag_domino.get_dots().x, drag_domino.get_dots().y, drag_domino.get_dots().x, drag_domino.get_dots().y])
		print("  Orientation: %d (%s)" % [drag_domino.data.orientation, _orientation_to_string(drag_domino.data.orientation)])
		
		# Verify connection is correct
		if required_dots >= 0:
			var left_side_actual = drag_domino.get_dots().x
			print("  Left side value: %d" % left_side_actual)
			print("  Connection check: %d should equal %d -> %s" % [left_side_actual, required_dots, str(left_side_actual == required_dots)])
		
		print("========== DOMINO DROP DEBUG END ==========\n")
		
		# Clean up drag metadata
		if get_tree().has_meta("current_drag_domino"):
			get_tree().remove_meta("current_drag_domino")
		if get_tree().has_meta("current_drag_source"):
			get_tree().remove_meta("current_drag_source")
		
		print("Domino successfully dropped into train")

func get_domino(i:int)-> Domino:
	return domino_container.get_child(i)
	
func remove_domino(index: int) -> Domino:
	"""Remove and return domino at given index"""
	if index < 0 or index >= get_domino_count():
		return null
	
	var domino = get_domino(index)
	domino_container.remove_child(domino)
	_update_train_size()
	return domino

func clear_dominoes() -> void:
	"""Remove all dominoes from train"""
	for child in domino_container.get_children():
		domino_container.remove_child(child)
	_update_train_size()

func get_last_domino() -> Domino:
	"""Get the last (rightmost/newest) domino in the train"""
	var count = get_domino_count()
	if count == 0:
		return null
	return get_domino(count - 1)

func get_first_domino() -> Domino:
	"""Get the first (leftmost/oldest) domino in the train"""
	if get_domino_count() == 0:
		return null
	return get_domino(0)

func move_domino(p_domino:Domino,p_dest) ->void:
	p_domino.reparent(p_dest)

## Enable this train as a drop target for dominoes
func enable_drop_target() -> void:
	# Ensure the train can receive mouse events for drag and drop
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Ensure child containers allow mouse events to pass through to the train
	if top_container:
		top_container.mouse_filter = Control.MOUSE_FILTER_PASS
	if domino_container:
		domino_container.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Ensure background allows events to pass through
	if has_node("TopContainer/bg"):
		var bg = $"TopContainer/bg"
		bg.mouse_filter = Control.MOUSE_FILTER_PASS
	
	print("Train enabled as drop target")

func _ready() -> void:
	# Set player name using PlayerNameUtil
	var player_name_util = preload("res://scripts/util/player_name_util.gd")
	set_label_text(player_name_util.get_train_label())
	self.color.a = 0
	# Enable drag & drop functionality
	enable_drop_target()

func _orient_domino_for_connection(domino: Domino) -> void:
	"""Orient the domino so it connects properly to the train"""
	var domino_dots = domino.get_dots()
	
	# If train is empty, orient first domino as if engine were immediately before it
	if get_domino_count() == 0:
		print("=== FIRST DOMINO ===")
		print("Orienting first domino %d-%d for engine connection" % [domino_dots.x, domino_dots.y])
		
		# Get the engine value from the station
		var station = find_station_in_scene()
		if station and station.has_engine():
			var engine_value = station.get_engine_value()
			print("Engine value: %d" % engine_value)
			
			# Orient domino so engine-matching side is on the left (connecting side)
			if domino_dots.x == engine_value:
				# The left value (x) matches engine - orient based on which side has more dots
				if domino_dots.x >= domino_dots.y:
					domino.set_orientation(DominoData.ORIENTATION_LARGEST_LEFT)
					print("Set first domino to LARGEST_LEFT (engine-matching %d on left)" % domino_dots.x)
				else:
					domino.set_orientation(DominoData.ORIENTATION_LARGEST_RIGHT)
					print("Set first domino to LARGEST_RIGHT (engine-matching %d on left)" % domino_dots.x)
			elif domino_dots.y == engine_value:
				# The right value (y) matches engine - swap so engine value is on left
				domino.set_dots(domino_dots.y, domino_dots.x)  # Swap so engine value is on left
				var new_dots = domino.get_dots()
				if new_dots.x >= new_dots.y:
					domino.set_orientation(DominoData.ORIENTATION_LARGEST_LEFT)
					print("Set first domino to LARGEST_LEFT after swapping (engine-matching %d now on left)" % new_dots.x)
				else:
					domino.set_orientation(DominoData.ORIENTATION_LARGEST_RIGHT)
					print("Set first domino to LARGEST_RIGHT after swapping (engine-matching %d now on left)" % new_dots.x)
			else:
				# This shouldn't happen if validation worked correctly
				print("WARNING: First domino %d-%d doesn't match engine %d" % [domino_dots.x, domino_dots.y, engine_value])
				# Default fallback
				if domino_dots.x >= domino_dots.y:
					domino.set_orientation(DominoData.ORIENTATION_LARGEST_LEFT)
				else:
					domino.set_orientation(DominoData.ORIENTATION_LARGEST_RIGHT)
		else:
			print("WARNING: No station or engine found - using default orientation")
			# Fallback to original behavior
			if domino_dots.x >= domino_dots.y:
				domino.set_orientation(DominoData.ORIENTATION_LARGEST_LEFT)
				print("Set first domino to LARGEST_LEFT (larger value %d on left)" % domino_dots.x)
			else:
				domino.set_orientation(DominoData.ORIENTATION_LARGEST_RIGHT)
				print("Set first domino to LARGEST_RIGHT (larger value %d on right)" % domino_dots.y)
		print("==================")
		return
	
	# Get the rightmost domino and its right-side dot count
	var last_domino = get_last_domino()
	if not last_domino:
		domino.set_orientation(DominoData.ORIENTATION_LARGEST_RIGHT)
		return  # Fallback if we can't get last domino
	
	# Get the correct right-side value based on domino orientation  
	var required_dots = _get_domino_right_side_value(last_domino)
	domino_dots = domino.get_dots()
	
	# We need the matching value on the LEFT side of the new domino
	# With (x,y) coordinates: x=left_dots, y=right_dots for horizontal dominoes
	
	print("=== ORIENTING DOMINO FOR CONNECTION ===")
	print("Need to connect to: %d dots" % required_dots)
	print("New domino data: %d-%d (x=left, y=right when horizontal)" % [domino_dots.x, domino_dots.y])
	print("Current domino orientation: %d" % domino.data.orientation)
	
	if domino_dots.x == required_dots:
		# The left value (x) matches - domino is already in correct orientation
		# Use orientation based on which side has more dots
		if domino_dots.x >= domino_dots.y:
			domino.set_orientation(DominoData.ORIENTATION_LARGEST_LEFT)
			print("Oriented domino %s as LARGEST_LEFT (left %d matches required %d)" % [domino.name, domino_dots.x, required_dots])
		else:
			domino.set_orientation(DominoData.ORIENTATION_LARGEST_RIGHT)
			print("Oriented domino %s as LARGEST_RIGHT (left %d matches required %d)" % [domino.name, domino_dots.x, required_dots])
	elif domino_dots.y == required_dots:
		# The right value (y) matches - need to flip domino so y becomes left side
		# This means swapping the domino's left/right values
		domino.set_dots(domino_dots.y, domino_dots.x)  # Swap so required value is on left
		var new_dots = domino.get_dots()
		if new_dots.x >= new_dots.y:
			domino.set_orientation(DominoData.ORIENTATION_LARGEST_LEFT)
			print("Oriented domino %s as LARGEST_LEFT after swapping (now left %d matches required %d)" % [domino.name, new_dots.x, required_dots])
		else:
			domino.set_orientation(DominoData.ORIENTATION_LARGEST_RIGHT)
			print("Oriented domino %s as LARGEST_RIGHT after swapping (now left %d matches required %d)" % [domino.name, new_dots.x, required_dots])
	else:
		# This shouldn't happen if _can_drop_data worked correctly
		print("WARNING: Domino %s cannot connect (needs %d, has %d-%d)" % [
			domino.name, required_dots, domino_dots.x, domino_dots.y])
		# Default to LARGEST_RIGHT as fallback
		domino.set_orientation(DominoData.ORIENTATION_LARGEST_RIGHT)
	
	print("Final domino orientation: %d" % domino.data.orientation)
	print("=====================================")

func _get_domino_right_side_value(domino: Domino) -> int:
	"""Get the dot value on the right side of a domino based on its orientation"""
	var dots = domino.get_dots()
	var orientation = domino.data.orientation
	
	print("DEBUG _get_domino_right_side_value:")
	print("  Domino dots: %d-%d (x=%d, y=%d)" % [dots.x, dots.y, dots.x, dots.y])
	print("  Orientation: %d (%s)" % [orientation, _orientation_to_string(orientation)])
	
	var right_side_value: int
	match orientation:
		DominoData.ORIENTATION_LARGEST_RIGHT:
			# LARGEST_RIGHT means the larger number is positioned on the right
			# So we need to determine which of x or y is larger and return that
			if dots.x >= dots.y:
				right_side_value = dots.x  # x is larger, so it's on the right
			else:
				right_side_value = dots.y  # y is larger, so it's on the right
			print("  LARGEST_RIGHT: larger value %d is on the right" % right_side_value)
		DominoData.ORIENTATION_LARGEST_LEFT:
			# LARGEST_LEFT means the larger number is positioned on the left
			# So the smaller number is on the right
			if dots.x >= dots.y:
				right_side_value = dots.y  # x is larger (on left), so y is on right
			else:
				right_side_value = dots.x  # y is larger (on left), so x is on right
			print("  LARGEST_LEFT: smaller value %d is on the right" % right_side_value)
		DominoData.ORIENTATION_LARGEST_TOP, DominoData.ORIENTATION_LARGEST_BOTTOM:
			# For vertical orientations, we shouldn't be connecting horizontally in trains
			print("  WARNING: Vertical orientation in horizontal train connection")
			right_side_value = dots.y  # Default fallback
		_:
			print("  ERROR: Unknown domino orientation %s" % orientation)
			right_side_value = dots.y  # Default fallback
	
	print("  Final right-side value: %d" % right_side_value)
	return right_side_value

# Helper function to convert orientation to string for debugging
func _orientation_to_string(orientation: int) -> String:
	"""Convert orientation constant to human-readable string"""
	match orientation:
		DominoData.ORIENTATION_LARGEST_LEFT:
			return "LARGEST_LEFT"
		DominoData.ORIENTATION_LARGEST_RIGHT:
			return "LARGEST_RIGHT"
		DominoData.ORIENTATION_LARGEST_TOP:
			return "LARGEST_TOP"
		DominoData.ORIENTATION_LARGEST_BOTTOM:
			return "LARGEST_BOTTOM"
		_:
			return "UNKNOWN(%d)" % orientation

func find_station_in_scene():
	"""Look for a Station node in the scene tree"""
	# Look for station in parent nodes
	var current = get_parent()
	while current:
		if current.has_method("get_engine_value"):
			return current
		# Look for station as sibling
		for child in current.get_children():
			if child.has_method("get_engine_value"):
				return child
		current = current.get_parent()
	
	# Look in the entire scene tree as fallback
	var scene_root = get_tree().current_scene
	if scene_root:
		var all_nodes = get_all_nodes_in_scene(scene_root)
		for node in all_nodes:
			if node.has_method("get_engine_value"):
				return node
	
	return null

func get_all_nodes_in_scene(node: Node) -> Array:
	"""Recursively get all nodes in the scene"""
	var nodes = [node]
	for child in node.get_children():
		nodes.append_array(get_all_nodes_in_scene(child))
	return nodes

func get_open_end() -> int:
	"""Get the dot value that the next domino must connect to (right side of last domino)"""
	var last_domino = get_last_domino()
	if not last_domino:
		# If train is empty, return the station's engine value
		var station = find_station_in_scene()
		if station and station.has_engine():
			return station.get_engine_value()
		return -1  # No valid connection
	
	return _get_domino_right_side_value(last_domino)

func clear_train() -> void:
	"""Clear all dominoes from the train"""
	clear_dominoes()
