extends Control

## Basic test script for domino functionality - right-click to toggle face up/down
var d_scene: PackedScene = preload("res://scenes/domino/domino.tscn") 
var test_domino: Domino

# Status label to display domino state
@onready var status_label: Label = $StatusLabel

func _ready() -> void:
	# Create a single test domino
	create_test_domino()
	
	# Update initial status
	update_status("Right-click the domino to toggle between face up and face down")

func create_test_domino() -> void:
	# Instantiate the domino from scene
	test_domino = d_scene.instantiate()
	
	# Add to the scene first
	add_child(test_domino)
	
	# Position it in the center of the screen
	test_domino.position = Vector2(400, 300)
	
	# Set random dots (0-12 range as requested) - do this after it's in the scene tree
	var left_dots = randi_range(0, 12)
	var right_dots = randi_range(0, 12)
	
	# Wait for the next frame to ensure the domino is fully initialized
	await get_tree().process_frame
	
	# Now set the dots
	test_domino.set_dots(left_dots, right_dots)
	
	# Start face up so we can see the dots
	test_domino.set_face_up(true)
	
	# Give it a name for debugging
	test_domino.name = "TestDomino_%d_%d" % [left_dots, right_dots]
		# Connect to the right-click signal
	test_domino.mouse_right_pressed.connect(_on_domino_right_clicked)
	
	# Ensure proper mouse handling
	test_domino.mouse_filter = Control.MOUSE_FILTER_STOP
	
	print("Created test domino with dots: %d-%d" % [left_dots, right_dots])
	print("Domino size: " + str(test_domino.size))
	print("Domino position: " + str(test_domino.position))
	print("Domino color: " + str(test_domino.color))
	print("Front size: " + str(test_domino.front.size if test_domino.front else "null"))
	print("Back size: " + str(test_domino.back.size if test_domino.back else "null"))
	print("Front visible: " + str(test_domino.front.visible if test_domino.front else "null"))
	print("Back visible: " + str(test_domino.back.visible if test_domino.back else "null"))
	update_status("Created domino with dots: %d-%d (Face Up)" % [left_dots, right_dots])

func _on_domino_right_clicked(domino: Domino) -> void:
	# Toggle the face up state
	domino.toggle_dots()
		# Update status
	var face_state = "Face Up" if domino.data.is_face_up else "Face Down"
	update_status("Domino %d-%d is now: %s" % [domino.get_dots().x, domino.get_dots().y, face_state])
	
	print("Domino right-clicked! New state: %s" % face_state)

func update_status(message: String) -> void:
	if status_label:
		status_label.text = message
	print("Status: %s" % message)
