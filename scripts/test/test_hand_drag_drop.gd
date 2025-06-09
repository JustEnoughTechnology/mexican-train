extends Control

## Test script for Hand drag and drop functionality
var d_scene: PackedScene = preload("res://scenes/domino/domino.tscn")
var hand_scene: PackedScene = preload("res://scenes/hand/hand.tscn")

# UI elements
@onready var status_label: Label = $StatusLabel
@onready var domino_pool: GridContainer = $DominoPool
@onready var test_hand: Hand = $TestHand

# Test dominoes array
var test_dominoes: Array[Domino] = []

func _ready() -> void:
	get_window().title = get_name()
	# Create the hand if it doesn't exist in the scene
	if not test_hand:
		create_test_hand()
	
	# Create a pool of test dominoes
	create_domino_pool(8)  # Create 8 test dominoes
	
	# Set up the hand as a drop target
	setup_hand_drop_target()
	
	# Update initial status
	update_status("Drag dominoes from the pool onto the hand below. Hand currently has %d dominoes." % test_hand.get_domino_count())

func create_test_hand() -> void:
	# Create hand instance
	test_hand = hand_scene.instantiate()
	test_hand.name = "TestHand"
	test_hand.label_text = "Test Hand"
	
	# Position it at the bottom of the screen
	test_hand.position = Vector2(50, 500)
	test_hand.size = Vector2(700, 100)
	
	# Add to scene
	add_child(test_hand)
	
	# Connect to hand signals
	test_hand.domino_count_changed.connect(_on_hand_domino_count_changed)
	
	print("Created test hand at position: " + str(test_hand.position))

func create_domino_pool(count: int) -> void:
	# Configure the domino pool container
	domino_pool.columns = min(count, 4)  # Max 4 columns
	domino_pool.size = Vector2(400, 200)
	domino_pool.position = Vector2(50, 50)
	
	# Create test dominoes
	for i in range(count):
		var domino = d_scene.instantiate()
		
		# Add to the pool container
		domino_pool.add_child(domino)
		
		# Wait for domino to be ready
		await get_tree().process_frame
		
		# Set random dots (0-6 range for standard dominoes)
		var left_dots = randi_range(0, 6)
		var right_dots = randi_range(0, 6)
		domino.set_dots(left_dots, right_dots)
		
		# Start face down so they need to be revealed in the hand
		domino.set_face_up(false)
		
		# Give it a unique name
		domino.name = "PoolDomino_%d_%d" % [left_dots, right_dots]
				# Ensure proper mouse handling for drag operations
		domino.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# Connect to domino signals for debugging
		domino.mouse_right_pressed.connect(_on_domino_right_clicked)
		
		# Add to our tracking array
		test_dominoes.append(domino)
		
		print("Created pool domino %d: %d-%d (face down), mouse_filter: %s" % [i, left_dots, right_dots, str(domino.mouse_filter)])
	
	print("Created domino pool with %d dominoes" % count)

func setup_hand_drop_target() -> void:
	# Enable the hand as a drop target
	if test_hand:
		test_hand.enable_drop_target()
		print("Hand drop target enabled")
		print("Hand is_drop_target_enabled: " + str(test_hand.is_drop_target_enabled))
		print("Hand mouse_filter: " + str(test_hand.mouse_filter))
		
		# Also check the child containers
		if test_hand.top_container:
			print("TopContainer mouse_filter: " + str(test_hand.top_container.mouse_filter))
		if test_hand.has_node("TopContainer/bg"):
			var bg = test_hand.get_node("TopContainer/bg")
			print("Background mouse_filter: " + str(bg.mouse_filter))
		if test_hand.domino_container:
			print("DominoContainer mouse_filter: " + str(test_hand.domino_container.mouse_filter))
	else:
		print("Warning: Could not enable hand drop target - hand not found")

func _on_hand_domino_count_changed() -> void:
	var count = test_hand.get_domino_count()
	update_status("Hand now has %d dominoes. Pool has %d dominoes remaining." % [count, domino_pool.get_child_count()])
	
	# Debug info about what's in the hand
	print("Hand domino count changed to: %d" % count)
	for i in range(count):
		var domino = test_hand.get_domino(i)
		if domino:
			print("Hand domino %d: %s (face up: %s)" % [i, str(domino.get_dots()), str(domino.data.is_face_up)])

func _on_domino_right_clicked(domino: Domino) -> void:
	# Right-click to toggle face up/down for testing
	domino.toggle_dots()
	var face_state = "Face Up" if domino.data.is_face_up else "Face Down"
	print("Domino right-clicked! %s is now: %s" % [domino.name, face_state])

func update_status(message: String) -> void:
	if status_label:
		status_label.text = message
	print("Status: %s" % message)

# Monitor for successful drag operations
func _process(_delta: float) -> void:
	# Clean up any lingering drag operations
	if Input.is_action_just_released("mouse_left") or Input.is_action_just_released("ui_cancel"):
		if get_tree().has_meta("current_drag_domino"):
			print("Cleaning up lingering drag operation")
			get_tree().remove_meta("current_drag_domino")
