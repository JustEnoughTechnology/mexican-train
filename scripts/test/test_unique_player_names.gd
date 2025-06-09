extends Control

## Test script to verify unique player naming functionality

@onready var player_name_util = preload("res://scripts/util/player_name_util.gd")
@onready var output_label = Label.new()

func _ready() -> void:
	get_window().title = "Unique Player Names Test"
	
	# Set up output label
	output_label.position = Vector2(20, 20)
	output_label.size = Vector2(800, 600)
	output_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	output_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	output_label.add_theme_font_size_override("font_size", 12)
	add_child(output_label)
	
	# Run the test
	test_unique_player_names()

func test_unique_player_names() -> void:
	var output = "=== UNIQUE PLAYER NAMES TEST ===\n\n"
	
	# Clear any existing names first
	player_name_util.clear_used_names()
	output += "1. Cleared used names list\n\n"
		# Test generating 8 unique player names (like in 8-player game)
	output += "2. Generating 8 unique player names:\n"
	var generated_names: Array[String] = []
	
	for i in range(1, 9):
		var player_name = player_name_util.get_unique_player_name(i)
		var hand_label = player_name_util.get_unique_hand_label(i)
		var train_label = player_name_util.get_unique_train_label(i)
		
		generated_names.append(player_name)
		output += "  Player %d: %s\n" % [i, player_name]
		output += "    Hand: %s\n" % hand_label
		output += "    Train: %s\n" % train_label
		output += "\n"
	
	# Test for uniqueness
	output += "3. Checking for uniqueness:\n"
	var unique_names = {}
	var duplicates_found = false
	
	for name in generated_names:
		if name in unique_names:
			output += "  ❌ DUPLICATE FOUND: %s\n" % name
			duplicates_found = true
		else:
			unique_names[name] = true
			output += "  ✅ Unique: %s\n" % name
	
	output += "\n"
	
	if duplicates_found:
		output += "❌ TEST FAILED: Duplicate names detected!\n"
	else:
		output += "✅ TEST PASSED: All %d names are unique!\n" % generated_names.size()
	
	# Test edge case: generating more names without numbers
	output += "\n4. Testing additional name generation without numbers:\n"
	for i in range(3):
		var extra_name = player_name_util.get_unique_player_name()
		output += "  Extra name %d: %s\n" % [i + 1, extra_name]
	
	# Show final used names list
	output += "\n5. Final used names list:\n"
	var used_names = player_name_util.used_player_names
	for i in range(used_names.size()):
		output += "  %d. %s\n" % [i + 1, used_names[i]]
	
	output += "\n=== TEST COMPLETE ===\n"
	output += "Total unique names generated: %d\n" % used_names.size()
	
	# Display results
	output_label.text = output
	print(output)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			# Restart test
			test_unique_player_names()
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()
