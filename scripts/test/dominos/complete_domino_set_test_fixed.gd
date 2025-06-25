extends Control

@onready var scroll_container = $VBoxContainer/ScrollContainer
@onready var domino_grid = $VBoxContainer/ScrollContainer/DominoGrid
@onready var status_label = $VBoxContainer/StatusLabel
@onready var generate_button = $VBoxContainer/GenerateButton
@onready var orientation_option = $VBoxContainer/OrientationControls/OrientationOption

var domino_pieces: Array = []

func _ready():
	setup_orientation_options()
	generate_button.pressed.connect(_on_generate_pressed)
	orientation_option.item_selected.connect(_on_orientation_changed)
	status_label.text = "Ready to generate complete double-12 domino set (91 pieces)"

func setup_orientation_options():
	orientation_option.add_item("Horizontal Left")
	orientation_option.add_item("Horizontal Right") 
	orientation_option.add_item("Vertical Top")
	orientation_option.add_item("Vertical Bottom")

func _on_generate_pressed():
	generate_all_dominos()

func _on_orientation_changed(index: int):
	update_all_orientations(index)

func generate_all_dominos():
	# Clear existing dominos
	for child in domino_grid.get_children():
		child.queue_free()
	domino_pieces.clear()
	
	status_label.text = "Generating dominos..."
	await get_tree().process_frame
	
	var domino_scene = preload("res://scenes/test/dominos/domino_piece.tscn")
	var count = 0
	
	# Generate all combinations from 0-0 to 12-12
	for largest in range(13):  # 0 to 12
		for smallest in range(largest + 1):  # 0 to largest (no duplicates)
			var domino = domino_scene.instantiate()
			domino.largest_value = largest
			domino.smallest_value = smallest
			domino.orientation = 0  # HORIZONTAL_LEFT
			
			# Add label showing the domino values
			var label = Label.new()
			label.text = domino.get_domino_string()
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			
			# Create container for domino and label
			var container = VBoxContainer.new()
			container.add_child(domino)
			container.add_child(label)
			
			domino_grid.add_child(container)
			domino_pieces.append(domino)
			count += 1
	
	status_label.text = "Generated %d domino pieces (complete double-12 set)" % count
	print("Successfully generated all %d domino combinations!" % count)

func update_all_orientations(orientation_index: int):
	var orientation_map = [
		0,  # HORIZONTAL_LEFT
		1,  # HORIZONTAL_RIGHT
		2,  # VERTICAL_TOP
		3   # VERTICAL_BOTTOM
	]
	
	var selected_orientation = orientation_map[orientation_index]
	
	for domino in domino_pieces:
		domino.orientation = selected_orientation
	
	status_label.text = "Updated orientation for all %d dominos" % domino_pieces.size()
