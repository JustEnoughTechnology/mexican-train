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
	
	# Add status label
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.position = Vector2(20, 150)
	status_label.size = Vector2(600, 50)
	status_label.add_theme_color_override("font_color", Color.YELLOW)
	add_child(status_label)
	
	update_status_label()
	
	print("NewDomino back test ready!")
	print("Starting face DOWN to show back immediately")

func update_status_label():
	var status_label = get_node("StatusLabel")
	if status_label:
		status_label.text = "Domino: %d-%d | Orientation: %d | Face: %s" % [
			test_domino.largest_value, 
			test_domino.smallest_value,
			test_domino.orientation,
			"UP (dots visible)" if test_domino.face_up else "DOWN (back visible)"
		]

func _unhandled_key_input(event):
	if not event.pressed:
		return
		
	match event.keycode:
		KEY_SPACE:
			# Toggle face up/down
			test_domino.toggle_face()
			update_status_label()
			print("Flipped! Face: %s" % ("UP" if test_domino.face_up else "DOWN"))
			
		KEY_O:
			# Cycle through orientations
			var current_orientation = test_domino.orientation
			var new_orientation = (current_orientation + 1) % 4
			test_domino.orientation = new_orientation
			update_status_label()
			print("Orientation: %d" % test_domino.orientation)
			
		KEY_V:
			# Switch to vertical
			test_domino.orientation = 2  # VERTICAL_TOP
			update_status_label()
			print("Orientation: %d" % test_domino.orientation)
			
		KEY_H:
			# Switch to horizontal
			test_domino.orientation = 0  # HORIZONTAL_LEFT
			update_status_label()
			print("Orientation: %d" % test_domino.orientation)
