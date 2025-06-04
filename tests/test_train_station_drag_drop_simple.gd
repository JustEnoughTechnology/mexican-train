extends Control

## Test script for Train drag and drop functionality with engine domino
var d_scene: PackedScene = preload("res://scenes/domino/domino.tscn")
var train_scene: PackedScene = preload("res://scenes/train/train.tscn")

# UI elements
@onready var domino_pool: GridContainer = $DominoPoolPanel/DominoPool
@onready var test_train: Train
@onready var test_station: Station

# Test dominoes array
var test_dominoes: Array[Domino] = []
var engine_domino: Domino = null

func _ready() -> void:
	get_window().title = get_name()
	
	# Create the train
	create_test_train()
	
	# Create the station
	create_test_station()
	# Create all dominoes from 0-0 to 6-6 in the pool
	create_complete_domino_set()
		# Update initial status - the station will show its own status
	print("STATUS: Drag the 6-6 domino to the station to start your train! Then drag other dominoes to extend it.")

func create_test_train() -> void:
	# Create train instance
	test_train = train_scene.instantiate()
	test_train.name = "TestTrain"
	test_train.label_text = "Test Train"
	
	# Add to the TrainContainer
	var train_container = $TrainContainer
	train_container.add_child(test_train)
	
	print("Created test train in TrainContainer")

func create_test_station() -> void:
	# Create station instance 
	var station_scene: PackedScene = preload("res://scenes/station/station.tscn")
	test_station = station_scene.instantiate()
	test_station.name = "TestStation"
	
	# Add to the StationContainer
	var station_container = $StationContainer
	station_container.add_child(test_station)
	
	# Position station at origin of container
	test_station.position = Vector2(0, 0)
	
	# Wait for station to be ready, then initialize as empty
	await test_station.ready
	test_station.initialize_empty()
	
	print("Created empty test station in StationContainer at position: ", test_station.position)
	print("Station container size: ", station_container.size)
	print("Station size: ", test_station.size)

func create_complete_domino_set() -> void:
	print("=== STARTING COMPLETE DOMINO SET CREATION ===")
	# The DominoPool GridContainer is already properly sized and positioned by the scene
	domino_pool.columns = 7  # Good layout for all 28 dominoes
	
	print("Starting complete domino creation...")
	print("DominoPool path: ", domino_pool.get_path())
	print("DominoPool size: ", domino_pool.size)
	print("DominoPool position: ", domino_pool.position)
	print("DominoPool initial child count: ", domino_pool.get_child_count())
	
	# Generate all 28 unique domino combinations from 0-0 to 6-6
	var all_dominoes = generate_all_domino_combinations()
	print("Generated %d domino combinations" % all_dominoes.size())
	
	if all_dominoes.size() != 28:
		print("ERROR: Expected 28 combinations, got %d" % all_dominoes.size())
		return
		# Create all dominoes
	for i in range(all_dominoes.size()):
		print("=== Creating domino %d of %d ===" % [i + 1, all_dominoes.size()])
		var domino = d_scene.instantiate()
		
		if not domino:
			print("ERROR: Failed to instantiate domino %d" % i)
			continue
				# Add to the pool container first
		domino_pool.add_child(domino)
		print("Added domino %d to pool container, child count now: %d" % [i, domino_pool.get_child_count()])
				# Set the domino data using the combination
		var combination = all_dominoes[i]
		print("Setting domino %d to combination: %s" % [i, combination])
		
		# Configure the domino
		domino.set_dots(combination.x, combination.y)
		domino.name = "PoolDomino_%d_%d" % [combination.x, combination.y]
		print("Set domino %d dots to %d-%d" % [i, combination.x, combination.y])
		
		# Make sure domino is face up so it's visible - IMPORTANT!
		domino.set_face_up(true)
		print("Set domino %d face up: %s" % [i, domino.data.is_face_up])
		
		# Set orientation for variety - alternate between left and right
		var orientation = DominoData.ORIENTATION_LARGEST_LEFT if i % 2 == 0 else DominoData.ORIENTATION_LARGEST_RIGHT
		domino.set_orientation(orientation)
		print("Set domino %d orientation: %s" % [i, _orientation_to_string(orientation)])
		
		# Store reference
		test_dominoes.append(domino)
		
		# Connect right-click signal
		if domino.has_signal("mouse_right_pressed"):
			domino.mouse_right_pressed.connect(_on_domino_right_clicked)
		
		# Special highlighting for the 6-6 domino
		if combination.x == 6 and combination.y == 6:
			engine_domino = domino
			print("*** 6-6 ENGINE DOMINO CREATED - drag it to the station! ***")
	
	print("=== DOMINO CREATION COMPLETE ===")
	print("Created %d dominoes in pool, including 6-6 engine" % test_dominoes.size())
	
	# Final verification - count what's actually in pool vs train
	var final_pool_count = domino_pool.get_child_count()
	var final_train_count = test_train.get_domino_count()
	print("FINAL COUNT: Pool has %d dominoes, Train has %d dominoes" % [final_pool_count, final_train_count])
	print("Expected: Pool should have 28 dominoes, Train should have 0 dominoes")

func generate_all_domino_combinations() -> Array[Vector2i]:
	"""Generate all 28 unique domino combinations from 0-0 to 6-6"""
	var all_dominoes: Array[Vector2i] = []
	
	# Generate all unique combinations where x >= y (avoid duplicates like 1-2 and 2-1)
	for y in range(0, 7):  # 0 to 6 (standard domino set)
		for x in range(y, 7):  # x >= y to avoid duplicates
			all_dominoes.append(Vector2i(x, y))
	
	print("Generated %d domino combinations" % all_dominoes.size())
	print("All combinations: ", all_dominoes)
	return all_dominoes



func _on_domino_right_clicked(domino: Domino) -> void:
	# Right-click to toggle face up/down for testing
	domino.toggle_dots()
	var face_state = "Face Up" if domino.data.is_face_up else "Face Down"
	print("Domino right-clicked! %s is now: %s" % [domino.name, face_state])

func update_status(message: String) -> void:
	# Print status messages to console since station has its own label
	print("STATUS: " + message)

func _input(event: InputEvent) -> void:
	# Handle spacebar to flip single domino orientation in train OR flip dragging domino
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			# Check if we're currently dragging a domino
			if get_tree().has_meta("current_drag_domino"):
				_toggle_dragging_domino_orientation()
			else:
				# No domino being dragged, try to flip single domino in train
				_toggle_single_domino_orientation()

func _toggle_single_domino_orientation() -> void:
	"""Toggle the orientation of a single domino in the train (spacebar functionality)"""
	if not test_train:
		return
	
	var domino_count = test_train.get_domino_count()
	
	# Only allow flipping if there's exactly one domino in the train
	if domino_count != 1:
		if domino_count == 0:
			print("No dominoes in train to flip")
		else:
			print("Cannot flip orientation: train has %d dominoes (only works with 1 domino)" % domino_count)
		return
	
	# Get the single domino and flip its orientation
	var domino = test_train.get_domino(0)
	var current_orientation = domino.data.orientation
	var new_orientation
	
	# Only flip between horizontal orientations
	if current_orientation == DominoData.ORIENTATION_LARGEST_LEFT:
		new_orientation = DominoData.ORIENTATION_LARGEST_RIGHT
	else:
		new_orientation = DominoData.ORIENTATION_LARGEST_LEFT
	
	# Apply the new orientation
	domino.set_orientation(new_orientation)
	
	var dots = domino.get_dots()
	print("Flipped single domino %d-%d from %s to %s" % [
		dots.x, dots.y, 
		_orientation_to_string(current_orientation),
		_orientation_to_string(new_orientation)
	])
		# Update status to show the change
	print("STATUS: Flipped single domino orientation! Press SPACEBAR again to flip back. Dots: %d-%d, Orientation: %s" % [
		dots.x, dots.y, _orientation_to_string(new_orientation)
	])

func _toggle_dragging_domino_orientation() -> void:
	"""Toggle the orientation of a domino currently being dragged (spacebar while dragging)"""
	var drag_domino = get_tree().get_meta("current_drag_domino")
	if not drag_domino or not drag_domino is Domino:
		return
	
	# Get current orientation and flip between horizontal orientations
	var current_orientation = drag_domino.data.orientation
	var new_orientation
	
	# Only flip between horizontal orientations for train compatibility
	if current_orientation == DominoData.ORIENTATION_LARGEST_LEFT:
		new_orientation = DominoData.ORIENTATION_LARGEST_RIGHT
	else:
		new_orientation = DominoData.ORIENTATION_LARGEST_LEFT
	
	# Apply the new orientation
	drag_domino.set_orientation(new_orientation)
	
	var dots = drag_domino.get_dots()
	print("Flipped DRAGGING domino %d-%d from %s to %s" % [
		dots.x, dots.y, 
		_orientation_to_string(current_orientation),
		_orientation_to_string(new_orientation)
	])
		# Update status to show the change
	print("STATUS: Flipped dragging domino orientation! Dots: %d-%d, Orientation: %s. Drop on train to test connection." % [
		dots.x, dots.y, _orientation_to_string(new_orientation)
	])

func _orientation_to_string(orientation: int) -> String:
	"""Convert orientation constant to readable string"""
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
			return "UNKNOWN"
