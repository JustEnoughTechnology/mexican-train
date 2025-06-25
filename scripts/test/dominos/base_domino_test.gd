extends Control

@onready var domino_container = $VBoxContainer

func _ready():
	# Set to maximized window mode for better viewing
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	
	# Load and display the sample base dominos
	load_sample_dominos()

func _input(event):
	# Press Escape to close
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func load_sample_dominos():
	# Load the two sample base dominos we created
	var domino_6_5_h = preload("res://scenes/dominos/base_dominos/base_domino_6_5_horizontal_left.tscn")
	var domino_9_8_v = preload("res://scenes/dominos/base_dominos/base_domino_9_8_vertical_top.tscn")
	
	# Create containers for each sample
	create_sample_display("6-5 Horizontal Left", domino_6_5_h)
	create_sample_display("9-8 Vertical Top", domino_9_8_v)

func create_sample_display(title: String, domino_scene: PackedScene):
	# Create a section for this domino sample
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 10)
	
	# Add title label
	var label = Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	section.add_child(label)
	
	# Add the domino instance
	var domino = domino_scene.instantiate()
	var domino_wrapper = HBoxContainer.new()
	domino_wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
	domino_wrapper.add_child(domino)
	section.add_child(domino_wrapper)
	
	# Add info about the domino
	var info = Label.new()
	var domino_info = domino.get_domino_info()
	info.text = "Size: %s | Orientation: %s" % [domino_info.size, domino_info.orientation_string]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 12)
	section.add_child(info)
	
	domino_container.add_child(section)
