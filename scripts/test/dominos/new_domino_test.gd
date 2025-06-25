extends Control

## Simple NewDomino Test - Test the new domino wrapper

@onready var container = $VBoxContainer

var domino_scene = preload("res://scenes/dominos/domino.tscn")

func _ready():
	test_dominoes()

func test_dominoes():
	"""Test a few specific dominoes."""
	
	# Test combinations with different orientations
	var test_cases = [
		{"largest": 6, "smallest": 5, "orientation": 0, "name": "6-5 Horizontal Left"},
		{"largest": 9, "smallest": 8, "orientation": 2, "name": "9-8 Vertical Top"},
		{"largest": 0, "smallest": 0, "orientation": 0, "name": "0-0 Blank"},
		{"largest": 12, "smallest": 12, "orientation": 1, "name": "12-12 Double Horizontal Right"},
	]
	
	for test_case in test_cases:
		create_test_domino(test_case)

func create_test_domino(test_case: Dictionary):
	"""Create a test domino display."""
	
	# Create horizontal container for label and domino
	var h_container = HBoxContainer.new()
	h_container.custom_minimum_size = Vector2(300, 100)
	
	# Create label
	var label = Label.new()
	label.text = test_case.name
	label.custom_minimum_size = Vector2(150, 50)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Create domino instance
	var domino_instance = domino_scene.instantiate()
	domino_instance.largest_value = test_case.largest
	domino_instance.smallest_value = test_case.smallest
	domino_instance.orientation = test_case.orientation
	
	# Set size based on orientation
	if test_case.orientation == 0 or test_case.orientation == 1:  # horizontal
		domino_instance.custom_minimum_size = Vector2(81, 40)
	else:  # vertical
		domino_instance.custom_minimum_size = Vector2(40, 81)
	
	# Add to container
	h_container.add_child(label)
	h_container.add_child(domino_instance)
	
	# Add separator
	var separator = HSeparator.new()
	
	# Add to main container
	container.add_child(h_container)
	container.add_child(separator)
	
	print("Created test domino: ", test_case.name)
