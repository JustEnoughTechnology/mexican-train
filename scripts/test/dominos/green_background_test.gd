extends Control

@onready var domino_grid = $ScrollContainer/DominoGrid
@onready var status_label = $StatusLabel

var domino_scenes: Array = []

func _ready():
	# Set to maximized window mode
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	generate_test_dominos()

func _input(event):
	# Press Escape to close the application
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func generate_test_dominos():
	var domino_scene = preload("res://scenes/dominos/domino.tscn")
	var count = 0
	
	# Test specific dominos: 6-6, 5-5, 0-0
	var test_values = [[6, 6], [5, 5], [0, 0]]
	
	for values in test_values:
		var largest = values[0]
		var smallest = values[1]
		
		var domino_container = VBoxContainer.new()
		domino_container.custom_minimum_size = Vector2(120, 140)
		
		# Create domino instance
		var domino = domino_scene.instantiate()
		domino.largest_value = largest
		domino.smallest_value = smallest
		domino.orientation = 0  # HORIZONTAL_LEFT
		
		# Create label
		var label = Label.new()
		label.text = "%d-%d" % [largest, smallest]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 16)
		
		# Add to container
		domino_container.add_child(domino)
		domino_container.add_child(label)
		
		# Add to grid
		domino_grid.add_child(domino_container)
		domino_scenes.append(domino)
		count += 1
	
	status_label.text = "Generated %d test domino pieces on green background" % count
	print("✅ Generated test dominos: 6-6, 5-5, 0-0")
