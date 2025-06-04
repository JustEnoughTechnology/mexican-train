extends Control

## Launcher for Mexican Train game components
## Provides easy access to test different parts of the game

@onready var button_container = $VBoxContainer/ButtonContainer

var test_scenes = {
	"Complete Game": "res://tests/test_complete_mexican_train.tscn",
	"Station + Train": "res://tests/test_train_station_drag_drop.tscn", 
	"Boneyard + Hand": "res://tests/test_boneyard_hand_drag_drop.tscn",
	"Hand Only": "res://tests/test_hand_drag_drop.tscn",
	"Train Only": "res://tests/test_train_drag_drop.tscn",
	"Station Only": "res://tests/test_station_only.tscn",
	"Boneyard Only": "res://tests/test_bone_yard.tscn"
}

func _ready() -> void:
	get_window().title = "Mexican Train Game Launcher"
	
	# Create buttons for each test scene
	for test_name in test_scenes.keys():
		var button = Button.new()
		button.text = test_name
		button.custom_minimum_size = Vector2(200, 40)
		button.connect("pressed", _on_test_button_pressed.bind(test_name))
		button_container.add_child(button)
	
	# Add info about the complete game
	update_info()

func update_info() -> void:
	var info_text = """
MEXICAN TRAIN GAME - Component Tests

COMPLETE GAME:
• All components integrated: Boneyard, Hand, Station, Train
• Full game flow: Collect dominoes → Place engine → Extend train
• Comprehensive Mexican Train experience

INDIVIDUAL COMPONENTS:
• Station + Train: Test engine placement and train extension
• Boneyard + Hand: Test domino collection and hand management  
• Individual tests: Test each component in isolation

CONTROLS (All Tests):
• Drag dominoes with mouse
• Right-click to flip face up/down
• Spacebar to toggle orientation overlays
• Enter to toggle debug warnings

GAME FLOW:
1. Drag dominoes from boneyard to your hand
2. Find and drag the 6-6 domino to the station (pink circle)
3. Once engine is placed, extend the train by matching dominoes
4. Build the longest train possible!
"""
	$VBoxContainer/InfoLabel.text = info_text

func _on_test_button_pressed(test_name: String) -> void:
	var scene_path = test_scenes[test_name]
	print("Loading test: %s (%s)" % [test_name, scene_path])
	
	# Check if scene exists
	if not FileAccess.file_exists(scene_path):
		print("Error: Scene file not found: %s" % scene_path)
		return
	
	# Load and switch to the test scene
	get_tree().change_scene_to_file(scene_path)
