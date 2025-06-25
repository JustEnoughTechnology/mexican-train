extends Control

## NewDomino Showcase - Display all dominoes in the double-12 set
## This demonstrates the new lightweight NewDomino wrapper system

@onready var scroll_container = $VBoxContainer/ScrollContainer
@onready var domino_grid = $VBoxContainer/ScrollContainer/DominoGrid
@onready var info_label = $VBoxContainer/InfoLabel

var domino_scene = preload("res://scenes/dominos/domino.tscn")
var current_orientation = NewDomino.Orientation.HORIZONTAL_LEFT

func _ready():
	setup_ui()
	create_all_dominoes()

func setup_ui():
	"""Set up the UI layout."""
	# Set up info label
	info_label.text = "Double-12 Domino Set Showcase - All 91 Dominoes"
	
	# Set up grid container
	domino_grid.columns = 13  # 13 columns for values 0-12

func create_all_dominoes():
	"""Create and display all dominoes in the double-12 set."""
	
	var domino_count = 0
	
	# Generate all domino combinations (0-0 through 12-12)
	for largest in range(13):  # 0 to 12
		for smallest in range(largest + 1):  # 0 to largest (to avoid duplicates)
			create_domino_display(largest, smallest)
			domino_count += 1
	
	# Update info label
	info_label.text = "Double-12 Domino Set Showcase - %d Dominoes (%s)" % [
		domino_count, get_orientation_name(current_orientation)
	]
	
	print("Created %d domino displays" % domino_count)

func create_domino_display(largest: int, smallest: int):
	"""Create a domino display for the given values."""
	
	# Create container for this domino
	var domino_container = VBoxContainer.new()
	domino_container.custom_minimum_size = Vector2(100, 120)
	
	# Create label
	var label = Label.new()
	label.text = "%d-%d" % [largest, smallest]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	
	# Create domino instance
	var domino_instance = domino_scene.instantiate()
	domino_instance.largest_value = largest
	domino_instance.smallest_value = smallest
	domino_instance.orientation = current_orientation
	
	# Set appropriate size
	var expected_size = get_expected_size_for_orientation(current_orientation)
	domino_instance.custom_minimum_size = expected_size
	domino_instance.size = expected_size
	
	# Add to container
	domino_container.add_child(label)
	domino_container.add_child(domino_instance)
	
	# Add to grid
	domino_grid.add_child(domino_container)

func get_expected_size_for_orientation(orientation: NewDomino.Orientation) -> Vector2:
	"""Get expected size for domino based on orientation."""
	match orientation:
		NewDomino.Orientation.HORIZONTAL_LEFT, NewDomino.Orientation.HORIZONTAL_RIGHT:
			return Vector2(81, 40)
		NewDomino.Orientation.VERTICAL_TOP, NewDomino.Orientation.VERTICAL_BOTTOM:
			return Vector2(40, 81)
		_:
			return Vector2(81, 40)

func get_orientation_name(orientation: NewDomino.Orientation) -> String:
	"""Get human-readable orientation name."""
	match orientation:
		NewDomino.Orientation.HORIZONTAL_LEFT:
			return "Horizontal Left"
		NewDomino.Orientation.HORIZONTAL_RIGHT:
			return "Horizontal Right"
		NewDomino.Orientation.VERTICAL_TOP:
			return "Vertical Top"
		NewDomino.Orientation.VERTICAL_BOTTOM:
			return "Vertical Bottom"
		_:
			return "Unknown"

func clear_dominoes():
	"""Clear all domino displays."""
	for child in domino_grid.get_children():
		child.queue_free()

func _on_orientation_button_pressed():
	"""Cycle through orientations when button is pressed."""
	
	# Cycle to next orientation
	match current_orientation:
		NewDomino.Orientation.HORIZONTAL_LEFT:
			current_orientation = NewDomino.Orientation.HORIZONTAL_RIGHT
		NewDomino.Orientation.HORIZONTAL_RIGHT:
			current_orientation = NewDomino.Orientation.VERTICAL_TOP
		NewDomino.Orientation.VERTICAL_TOP:
			current_orientation = NewDomino.Orientation.VERTICAL_BOTTOM
		NewDomino.Orientation.VERTICAL_BOTTOM:
			current_orientation = NewDomino.Orientation.HORIZONTAL_LEFT
	
	# Clear and recreate all dominoes
	clear_dominoes()
	create_all_dominoes()

func _on_test_specific_button_pressed():
	"""Test a few specific dominoes for detailed verification."""
	
	clear_dominoes()
	
	# Test specific combinations
	var test_dominoes = [
		[0, 0],   # Blank
		[6, 5],   # Our test domino
		[9, 8],   # Our other test domino
		[12, 12], # Double-12 (highest)
		[12, 0],  # High-low combination
		[7, 3],   # Random middle
	]
	
	for domino_values in test_dominoes:
		create_domino_display(domino_values[0], domino_values[1])
	
	info_label.text = "Test Dominoes - %d Selected (%s)" % [
		test_dominoes.size(), get_orientation_name(current_orientation)
	]

func _on_all_dominoes_button_pressed():
	"""Show all dominoes again."""
	clear_dominoes()
	create_all_dominoes()
