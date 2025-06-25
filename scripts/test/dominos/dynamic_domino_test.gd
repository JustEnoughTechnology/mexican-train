extends Control

@onready var largest_spinbox = $VBoxContainer/Controls/LargestSpinBox
@onready var smallest_spinbox = $VBoxContainer/Controls/SmallestSpinBox
@onready var orientation_option = $VBoxContainer/Controls/OrientationOption
@onready var update_button = $VBoxContainer/Controls/UpdateButton
@onready var domino_display = $VBoxContainer/DominoContainer/DominoDisplay

var current_domino

func _ready():
	setup_orientation_options()
	setup_signals()
	create_initial_domino()

func setup_orientation_options():
	orientation_option.add_item("Horizontal Left (Largest → Smallest)")
	orientation_option.add_item("Horizontal Right (Smallest ← Largest)")
	orientation_option.add_item("Vertical Top (Largest ↓ Smallest)")
	orientation_option.add_item("Vertical Bottom (Smallest ↑ Largest)")

func setup_signals():
	update_button.pressed.connect(_on_update_pressed)
	largest_spinbox.value_changed.connect(_on_value_changed)
	smallest_spinbox.value_changed.connect(_on_value_changed)
	orientation_option.item_selected.connect(_on_orientation_changed)

func create_initial_domino():
	# Load the domino piece scene
	var domino_scene = preload("res://scenes/test/dominos/domino_piece.tscn")
	current_domino = domino_scene.instantiate()	# Set initial values
	current_domino.largest_value = 6
	current_domino.smallest_value = 3
	current_domino.orientation = 0  # HORIZONTAL_LEFT
	
	# Add to display
	domino_display.add_child(current_domino)
	
	# Update UI to match
	largest_spinbox.value = 6
	smallest_spinbox.value = 3
	orientation_option.selected = 0

func _on_update_pressed():
	update_domino()

func _on_value_changed(_value):
	update_domino()

func _on_orientation_changed(_index):
	update_domino()

func update_domino():
	if current_domino:
		# Ensure largest is actually larger (or equal for doubles)
		var largest = int(max(largest_spinbox.value, smallest_spinbox.value))
		var smallest = int(min(largest_spinbox.value, smallest_spinbox.value))
		
		# Update the spinboxes if we had to swap
		if largest != largest_spinbox.value or smallest != smallest_spinbox.value:
			largest_spinbox.value = largest
			smallest_spinbox.value = smallest		# Update domino properties
		current_domino.largest_value = largest
		current_domino.smallest_value = smallest
		current_domino.orientation = orientation_option.selected
		
		# Update display label
		var orientation_text = orientation_option.get_item_text(orientation_option.selected)
		var domino_label = $VBoxContainer/DominoContainer/DominoLabel
		domino_label.text = "Domino %d-%d (%s)" % [largest, smallest, orientation_text]
