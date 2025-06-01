extends Control

## Test script for domino drag and drop functionality with a player hand using native Godot drag and drop
var d_scene: PackedScene = preload("res://scenes/domino/domino.tscn") 
var d: Domino

# Status label to display drag and drop operations
@onready var status_label: Label = $StatusLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Create a pool of dominos for testing
	create_test_dominos(12) # Create 12 random dominos
	
	# Connect to hand's signal to update status when dominos are added/removed
	$Hand.domino_count_changed.connect(_on_hand_domino_count_changed)
	
	# Set up drop targets
	setup_drop_targets()
	
	# Ensure the domino container in the test scene is properly configured
	var domino_container = $dominos
	domino_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	domino_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Update initial status
	update_status("Ready to test drag and drop. Drag face-down dominos to reveal them in your hand.")

# Creates a set of test dominos with random dots
func create_test_dominos(count: int) -> void:
	# Configure the domino container
	var domino_container = $dominos
	if domino_container is GridContainer:
		domino_container.columns = count if count < 8 else 8
	
	# Create dominoes
	for i in range(count):
		# Instantiate the domino from scene
		d = d_scene.instantiate()
		
		# Add to container before configuring (to establish proper parent relationship)
		domino_container.add_child(d)
		
		# Set the dots and make sure it's face down initially
		d.set_dots(randi_range(0, 6), randi_range(0, 6))
		d.set_face_up(false)
		
		# Give each domino a unique name for debugging
		d.name = "Domino_%d_%d" % [d.get_dots().x, d.get_dots().y]
		
		# Connect to the domino_dropped signal to handle drops
		d.domino_dropped.connect(_on_domino_dropped)
		
		# Use the original size from the scene (82x40) not 60x120
		# This ensures consistency with the scene definition
		d.custom_minimum_size = Vector2(82, 40)
		d.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# Ensure the container within the domino has proper size, orientation, and z-index
		if d.has_node("CenterContainer"):
			# Make sure container matches domino size exactly
			d.container.custom_minimum_size = Vector2(82, 40)
			d.container.rotation = 0
			
			# Set proper z-index ordering
			d.z_index = 0  # Base ColorRect (domino) at bottom
			d.container.z_index = 1  # CenterContainer in middle
			
			# Make sure front and back elements are properly aligned and on top
			if d.front:
				d.front.rotation = 0
				d.front.z_index = 2
				
			if d.back:
				d.back.rotation = 0
				d.back.z_index = 2

# Set up drop targets for testing
func setup_drop_targets() -> void:
	# Enable the hand as a drop target
	$Hand.enable_drop_target()
	print("Native drag and drop setup complete")

# Update the status label
func update_status(message: String) -> void:
	status_label.text = message

# Called when a domino is dropped onto another domino
func _on_domino_dropped(target: Domino, dropped: Domino) -> void:
	# This is for domino-to-domino drops, not domino-to-hand
	update_status("Domino %s-%s dropped onto domino %s-%s" % 
		[dropped.get_dots().x, dropped.get_dots().y, target.get_dots().x, target.get_dots().y])

# Called when the hand's domino count changes
func _on_hand_domino_count_changed() -> void:
	update_status("Hand now has %d dominoes - any dropped dominoes are now face up" % $Hand.get_domino_count())

# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	# Check if the left mouse button is released and clean up any lingering drag operations
	if Input.is_action_just_released("mouse_left") or Input.is_action_just_released("ui_cancel"):
		if get_tree().has_meta("current_drag_domino"):
			print("Cleaning up lingering drag operation")
			get_tree().remove_meta("current_drag_domino")
	pass


			
					
