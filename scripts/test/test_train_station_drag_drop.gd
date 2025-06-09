extends Control

## Test script for Train drag and drop functionality with engine domino
var d_scene: PackedScene = preload("res://scenes/domino/domino.tscn")
var train_scene: PackedScene = preload("res://scenes/train/train.tscn")

# UI elements
@onready var status_label: Label = $StatusLabel
@onready var domino_pool: GridContainer = $DominoPool
@onready var test_train: Train

# Test dominoes array
var test_dominoes: Array[Domino] = []
var engine_domino: Domino = null

func _ready() -> void:
	get_window().title = get_name()
	
	# Create the train
	create_test_train()
	
	# Create all 28 dominoes, then move 6-6 to train as engine
	create_complete_domino_set()
	
	# Update initial status
	update_status("6-6 engine in train. Drag dominoes from pool to extend train. Only dominoes with matching dots can connect! Press SPACEBAR to flip orientation.")

func create_test_train() -> void:
	# Create train instance
	test_train = train_scene.instantiate()
	test_train.name = "TestTrain"
	test_train.label_text = "Test Train"
	
	# Add to the TrainContainer
	var train_container = $TrainContainer
	train_container.add_child(test_train)
	
	print("Created test train in TrainContainer")

func create_complete_domino_set() -> void:
	# The DominoPool GridContainer is already properly sized and positioned by the scene
	domino_pool.columns = 7  # Good layout for remaining dominoes after moving 6-6 to train
	
	# Generate all 28 unique domino combinations
	var unique_dominoes = generate_unique_domino_set(28)
	
	# Create all test dominoes
	for i in range(unique_dominoes.size()):
		var domino = d_scene.instantiate()
		
		# Add to the pool container first
		domino_pool.add_child(domino)
		domino_pool.add_child(domino)
		
		# Wait for domino to be ready
		await domino.ready
		
		# Set the domino data using the unique combination
		var combination = unique_dominoes[i]
		domino.set_dots(combination.x, combination.y)
		domino.name = "PoolDomino_%d_%d" % [combination.x, combination.y]
		
		# Set orientation for variety - alternate between left and right
		var orientation = DominoData.ORIENTATION_LARGEST_LEFT if i % 2 == 0 else DominoData.ORIENTATION_LARGEST_RIGHT
		domino.set_orientation(orientation)
		
		# Store reference
		test_dominoes.append(domino)
		
		# Connect right-click signal
		if domino.has_signal("mouse_right_pressed"):
			domino.mouse_right_pressed.connect(_on_domino_right_clicked)
	
	print("Created %d test dominoes in pool (excluding 6-6 which is in station)" % test_dominoes.size())

func generate_unique_domino_set_excluding_double_six(max_count: int) -> Array[Vector2i]:
	"""Generate a list of unique domino combinations excluding 6-6 (which is in the station)"""
	var unique_dominoes: Array[Vector2i] = []
	
	# Generate all unique combinations where larger >= smaller (avoid duplicates)
	for smaller in range(0, 7):  # 0 to 6 (standard domino set)
		for larger in range(smaller, 7):  # larger >= smaller
			# Skip the 6-6 domino since it's in the station
			if larger == 6 and smaller == 6:
				continue
				
			unique_dominoes.append(Vector2i(larger, smaller))
			
			# Stop if we reach the requested count
			if unique_dominoes.size() >= max_count:
				break
		if unique_dominoes.size() >= max_count:
			break
	
	# Shuffle the dominoes for variety
	unique_dominoes.shuffle()
	
	print("Generated %d unique domino combinations (excluding 6-6)" % unique_dominoes.size())
	return unique_dominoes

func _on_domino_right_clicked(domino: Domino) -> void:
	# Right-click to toggle face up/down for testing
	domino.toggle_dots()
	var face_state = "Face Up" if domino.data.is_face_up else "Face Down"
	print("Domino right-clicked! %s is now: %s" % [domino.name, face_state])

func update_status(message: String) -> void:
	if status_label:
		status_label.text = message

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
	update_status("Flipped single domino orientation! Press SPACEBAR again to flip back. Dots: %d-%d, Orientation: %s" % [
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
	update_status("Flipped dragging domino orientation! Dots: %d-%d, Orientation: %s. Drop on train to test connection." % [
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
