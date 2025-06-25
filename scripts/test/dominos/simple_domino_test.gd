extends Control

@onready var test_container = $TestContainer

func _ready():
	# Set to maximized window mode
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	create_test_dominos()

func _input(event):
	# Press Escape to close the application
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func create_test_dominos():
	var domino_scene = preload("res://scenes/dominos/domino.tscn")
	
	# Create 6-6 domino
	var domino_6_6 = domino_scene.instantiate()
	domino_6_6.largest_value = 6
	domino_6_6.smallest_value = 6
	domino_6_6.orientation = 0  # HORIZONTAL_LEFT
	domino_6_6.position = Vector2(100, 100)
	
	# Create 5-5 domino
	var domino_5_5 = domino_scene.instantiate()
	domino_5_5.largest_value = 5
	domino_5_5.smallest_value = 5
	domino_5_5.orientation = 0  # HORIZONTAL_LEFT
	domino_5_5.position = Vector2(300, 100)
	
	# Create 0-0 domino
	var domino_0_0 = domino_scene.instantiate()
	domino_0_0.largest_value = 0
	domino_0_0.smallest_value = 0
	domino_0_0.orientation = 0  # HORIZONTAL_LEFT
	domino_0_0.position = Vector2(500, 100)
	
	# Add labels
	var label_6_6 = Label.new()
	label_6_6.text = "6-6 Double"
	label_6_6.position = Vector2(100, 200)
	label_6_6.add_theme_font_size_override("font_size", 16)
	
	var label_5_5 = Label.new()
	label_5_5.text = "5-5 Double"
	label_5_5.position = Vector2(300, 200)
	label_5_5.add_theme_font_size_override("font_size", 16)
	
	var label_0_0 = Label.new()
	label_0_0.text = "0-0 Double"
	label_0_0.position = Vector2(500, 200)
	label_0_0.add_theme_font_size_override("font_size", 16)
	
	# Add to container
	test_container.add_child(domino_6_6)
	test_container.add_child(domino_5_5)
	test_container.add_child(domino_0_0)
	test_container.add_child(label_6_6)
	test_container.add_child(label_5_5)
	test_container.add_child(label_0_0)
