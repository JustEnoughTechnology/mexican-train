extends Control

## Test script for Train drag and drop functionality
var d_scene: PackedScene = preload("res://scenes/domino/domino.tscn")
var train_scene: PackedScene = preload("res://scenes/train/train.tscn")

# UI elements
@onready var status_label: Label = $StatusLabel
@onready var domino_pool: GridContainer = $DominoPool
@onready var test_train: Train

# Test dominoes array
var test_dominoes: Array[Domino] = []

func _ready() -> void:
	get_window().title = get_name()
	
	# Create the train
	create_test_train()
		# Create a pool of test dominoes
	create_domino_pool(28)  # Create ALL 28 unique dominoes for thorough testing	# Update initial status
	update_status("Drag dominoes from pool to train. ALL 28 unique dominoes available! Press SPACEBAR to flip orientation (works while dragging OR with single domino in train).")

func create_test_train() -> void:
	# Create train instance
	test_train = train_scene.instantiate()
	test_train.name = "TestTrain"
	test_train.label_text = "Test Train"
	
	# Add to the TrainContainer instead of positioning manually
	var train_container = $TrainContainer
	train_container.add_child(test_train)
	
	print("Created test train in TrainContainer")

func create_domino_pool(count: int) -> void:
	# The DominoPool GridContainer is already properly sized and positioned by the scene
	# Just configure the columns for good layout
	domino_pool.columns = 7  # Good layout for 28 dominoes (4 rows of 7)
	
	# Generate unique domino combinations for a standard set
	var unique_dominoes = generate_unique_domino_set(count)
	
	# Create test dominoes from unique combinations
	for i in range(min(count, unique_dominoes.size())):
		var domino = d_scene.instantiate()
		
		# Add to the pool container
		domino_pool.add_child(domino)
		
		# Wait for domino to be ready
		await get_tree().process_frame
		
		# Set the unique domino dots
		var domino_data = unique_dominoes[i]
		domino.set_dots(domino_data.x, domino_data.y)
		
		# Start face up so we can see them
		domino.set_face_up(true)
		
		# Give it a unique name
		domino.name = "PoolDomino_%d_%d" % [domino_data.x, domino_data.y]
		
		# Ensure proper mouse handling for drag operations
		domino.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# Connect to domino signals for debugging
		domino.mouse_right_pressed.connect(_on_domino_right_clicked)
		
		# Add to our tracking array
		test_dominoes.append(domino)
		
		print("Created pool domino %d: %d-%d (face up), mouse_filter: %s" % [i, domino_data.x, domino_data.y, str(domino.mouse_filter)])
	
	print("Created domino pool with %d unique dominoes" % min(count, unique_dominoes.size()))
	
	# Update the initial status
	_update_status_display()

func generate_unique_domino_set(max_count: int) -> Array[Vector2i]:
	"""Generate a list of unique domino combinations (double-six standard set)"""
	var unique_dominoes: Array[Vector2i] = []
	
	# Generate all unique combinations where larger >= smaller (avoid duplicates)
	for smaller in range(0, 7):  # 0 to 6 (standard domino set)
		for larger in range(smaller, 7):  # larger >= smaller
			unique_dominoes.append(Vector2i(larger, smaller))
			
			# Stop if we reach the requested count
			if unique_dominoes.size() >= max_count:
				break
		if unique_dominoes.size() >= max_count:
			break
	
	# Shuffle the dominoes for variety
	unique_dominoes.shuffle()
	
	print("Generated %d unique domino combinations" % unique_dominoes.size())
	return unique_dominoes

func _on_domino_right_clicked(domino: Domino) -> void:
	# Right-click to toggle face up/down for testing
	domino.toggle_dots()
	var face_state = "Face Up" if domino.data.is_face_up else "Face Down"
	print("Domino right-clicked! %s is now: %s" % [domino.name, face_state])

func update_status(message: String) -> void:
	if status_label:
		status_label.text = message
	# Removed print statement to stop console spam

func _update_status_display() -> void:
	# Manual status update only when called
	if test_train:
		var current_count = test_train.get_domino_count()
		var pool_count = domino_pool.get_child_count()
		update_status("Train has %d dominoes. Pool has %d dominoes remaining." % [current_count, pool_count])

# Monitor for successful drag operations
func _process(_delta: float) -> void:
	# Clean up any lingering drag operations
	if Input.is_action_just_released("mouse_left") or Input.is_action_just_released("ui_cancel"):
		if get_tree().has_meta("current_drag_domino"):
			print("Cleaning up lingering drag operation")
			get_tree().remove_meta("current_drag_domino")

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
	
	var single_domino = test_train.get_domino(0)
	if not single_domino:
		return
	
	# Get current orientation and flip it
	var current_orientation = single_domino.data.orientation
	var new_orientation
	
	if current_orientation == DominoData.ORIENTATION_LARGEST_LEFT:
		new_orientation = DominoData.ORIENTATION_LARGEST_RIGHT
	else:
		new_orientation = DominoData.ORIENTATION_LARGEST_LEFT
	
	# Apply the new orientation
	single_domino.set_orientation(new_orientation)
	
	var dots = single_domino.get_dots()
	print("Flipped domino %d-%d from %s to %s" % [
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
