extends Control

## Player Layout 8 Clean Test
## Tests the 8-player layout for Mexican Train game

func _ready() -> void:
	print("player_layout_8_clean_test.gd loaded")
	get_window().title = "Mexican Train - 8 Player Layout Test"
	
	# Create a simple test layout
	var label = Label.new()
	label.text = "8-Player Layout Test\nThis would test player positioning around the game board."
	label.anchors_preset = Control.PRESET_CENTER
	add_child(label)
	
	# Add test functionality here
	test_player_positions()

func test_player_positions() -> void:
	# Test 8-player circular layout
	print("Testing 8-player circular layout positions")
	
	var center = Vector2(400, 300)
	var radius = 200
	
	for i in range(8):
		var angle = i * PI / 4  # 8 positions around circle
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		print("Player %d position: %s" % [i + 1, pos])