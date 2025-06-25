extends Control

## Test scene for NewDomino back functionality
## Shows a domino that can be flipped between face up and face down

var test_domino: Control  # Use Control type to avoid class resolution issues

func _ready():
	get_window().title = "NewDomino Back Test"
	
	# Create test domino
	test_domino = preload("res://scenes/dominos/domino.tscn").instantiate()
	add_child(test_domino)
	
	# Set up test domino
	test_domino.largest_value = 9
	test_domino.smallest_value = 4
	test_domino.orientation = 0  # HORIZONTAL_LEFT
	test_domino.face_up = false  # Start face DOWN to see the back immediately
	
	# Position in center
	test_domino.position = Vector2(400, 300)
	
	# Add instructions
	var label = Label.new()
	label.text = "NewDomino Back Test\n\nPress SPACE to flip domino\nPress O to change orientation\nPress V to switch to vertical\nPress H to switch to horizontal"
	label.position = Vector2(20, 20)
	label.size = Vector2(400, 100)
	add_child(label)
	
	# Connect to orientation change signal for testing
	test_domino.orientation_changed.connect(_on_orientation_changed)
	test_domino.face_changed.connect(_on_face_changed)
	
	print("NewDomino back test ready!")
	print("Starting face DOWN to show back immediately")

func _on_orientation_changed(new_orientation: int, old_orientation: int):
	var orientation_names = ["HORIZONTAL_LEFT", "HORIZONTAL_RIGHT", "VERTICAL_TOP", "VERTICAL_BOTTOM"]
	var old_name = orientation_names[old_orientation] if old_orientation < orientation_names.size() else "UNKNOWN"
	var new_name = orientation_names[new_orientation] if new_orientation < orientation_names.size() else "UNKNOWN"
	print("SIGNAL: Orientation changed from %s to %s" % [old_name, new_name])

func _on_face_changed(is_face_up: bool):
	print("SIGNAL: Face changed to %s" % ("UP (dots visible)" if is_face_up else "DOWN (back visible)"))

func _unhandled_key_input(event):
	if not event.pressed:
		return
		
	match event.keycode:
		KEY_SPACE:
			# Toggle face up/down
			test_domino.toggle_face()
			print("Flipped! Face: %s" % ("UP" if test_domino.face_up else "DOWN"))
			
		KEY_O:
			# Cycle through orientations
			var current_orientation = test_domino.orientation
			var new_orientation = (current_orientation + 1) % 4
			test_domino.orientation = new_orientation
			print("Orientation: %d" % test_domino.orientation)
			
		KEY_V:
			# Switch to vertical
			test_domino.orientation = 2  # VERTICAL_TOP
			print("Orientation: %d" % test_domino.orientation)
			
		KEY_H:
			# Switch to horizontal
			test_domino.orientation = 0  # HORIZONTAL_LEFT
			print("Orientation: %d" % test_domino.orientation)
