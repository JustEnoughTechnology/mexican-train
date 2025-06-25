extends Control

@onready var scroll_container = $ScrollContainer
@onready var domino_grid = $ScrollContainer/DominoGrid
@onready var status_label = $StatusLabel
@onready var orientation_option = $"OrientationControls#OrientationOption"
@onready var generate_button = $"OrientationControls#GenerateButton"

var domino_scenes: Array = []

func _ready():
	# Set to maximized window mode
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	setup_ui()
	generate_all_dominos()

func _input(event):
	# Press Escape to close the application
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func setup_ui():
	# Setup orientation options
	orientation_option.add_item("Horizontal Left (Largest → Smallest)")
	orientation_option.add_item("Horizontal Right (Smallest ← Largest)")
	orientation_option.add_item("Vertical Top (Largest ↓ Smallest)")
	orientation_option.add_item("Vertical Bottom (Smallest ↑ Largest)")
	
	# Connect signals
	orientation_option.item_selected.connect(_on_orientation_changed)
	generate_button.pressed.connect(generate_all_dominos)

func generate_all_dominos():
	# Clear existing dominos
	for child in domino_grid.get_children():
		child.queue_free()
	domino_scenes.clear()
	
	status_label.text = "Generating test dominos..."
	await get_tree().process_frame
	
	var domino_scene = preload("res://scenes/dominos/domino.tscn")
	var count = 0
	
	# Generate only specific test dominos: 6-6, 5-5, 0-0
	var test_combinations = [[6, 6], [5, 5], [0, 0]]
	
	for combo in test_combinations:
		var largest = combo[0]
		var smallest = combo[1]
		
		var domino_container = VBoxContainer.new()
		domino_container.custom_minimum_size = Vector2(100, 120)
		domino_container.alignment = BoxContainer.ALIGNMENT_CENTER
				# Create domino instance
		var domino = domino_scene.instantiate()
		domino.custom_minimum_size = Vector2(81, 40)  # 40px + 1px + 40px = 81px width
		domino.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		domino.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
	
	status_label.text = "Generated %d test domino pieces: 6-6, 5-5, 0-0" % count
	print("✅ Generated test dominos: 6-6, 5-5, 0-0")

func _on_orientation_changed(index: int):
	# 0=HORIZONTAL_LEFT, 1=HORIZONTAL_RIGHT, 2=VERTICAL_TOP, 3=VERTICAL_BOTTOM
	for domino in domino_scenes:
		domino.orientation = index
	
	var orientation_names = [
		"Horizontal Left", "Horizontal Right", 
		"Vertical Top", "Vertical Bottom"
	]
	status_label.text = "All %d dominos set to %s orientation" % [domino_scenes.size(), orientation_names[index]]
