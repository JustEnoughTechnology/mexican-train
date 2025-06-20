extends Control

## Test script for experimental shader-based dominoes
## This validates that the shader system works correctly

@onready var test_container = $VBoxContainer/TestContainer

func _ready():
	print("Starting experimental domino test...")
	create_test_dominoes()

func create_test_dominoes():
	"""Create a variety of test dominoes to verify the system."""
	
	# Test data: [left_dots, right_dots, orientation, label]
	var test_cases = [
		[1, 1, "top", "1-1 Light Blue"],
		[3, 6, "top", "3-6 Pink/Yellow"], 
		[9, 12, "top", "9-12 Royal Purple/Gray"],
		[15, 18, "top", "15-18 Classic Purple/Red"],
		[0, 0, "top", "0-0 Blank"],
		[6, 6, "left", "6-6 Yellow (Horizontal)"]
	]
	
	for i in range(test_cases.size()):
		var test_case = test_cases[i]
		create_test_domino(test_case[0], test_case[1], test_case[2], test_case[3], i)

func create_test_domino(left: int, right: int, orientation: String, label: String, index: int):
	"""Create a single test domino."""
	
	# Create container for this test
	var test_group = VBoxContainer.new()
	test_container.add_child(test_group)
	
	# Add label
	var label_node = Label.new()
	label_node.text = label
	label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	test_group.add_child(label_node)
	
	# Create the experimental domino
	var domino = preload("res://scenes/experimental/experimental_domino.tscn").instantiate()
	domino.configure_domino(left, right, orientation)
	domino.custom_minimum_size = Vector2(80, 164)  # Reasonable size for testing
	
	test_group.add_child(domino)
	
	print("Created test domino %d: %s" % [index + 1, label])

func _on_refresh_button_pressed():
	"""Refresh the test by recreating all dominoes."""
	# Clear existing test dominoes
	for child in test_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	create_test_dominoes()
	print("Test dominoes refreshed")
