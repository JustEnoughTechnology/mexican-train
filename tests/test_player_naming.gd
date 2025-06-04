extends Control

# Test script to verify player naming functionality

@onready var hand_scene = preload("res://scenes/hand/hand.tscn")
@onready var train_scene = preload("res://scenes/train/train.tscn")
@onready var player_name_util = preload("res://scripts/util/player_name_util.gd")

func _ready() -> void:
	get_window().title = "Player Naming Test"
	
	print("=== PLAYER NAMING TEST ===")
	
	# Test PlayerNameUtil directly
	print("\n1. Testing PlayerNameUtil methods:")
	var player_name = player_name_util.get_player_name()
	print("  Player name: '%s'" % player_name)
	
	var os_username = player_name_util.get_os_username()
	print("  OS username: '%s'" % os_username)
	
	var hand_label = player_name_util.get_hand_label()
	print("  Hand label: '%s'" % hand_label)
	
	var train_label = player_name_util.get_train_label()
	print("  Train label: '%s'" % train_label)
	
	# Test with custom player name
	var custom_hand_label = player_name_util.get_hand_label("TestPlayer")
	print("  Custom hand label: '%s'" % custom_hand_label)
	
	# Test actual Hand and Train instances
	print("\n2. Testing Hand and Train instances:")
	
	# Create a Hand instance
	var test_hand = hand_scene.instantiate()
	add_child(test_hand)
	test_hand.position = Vector2(50, 50)
	
	# Wait a frame for _ready to execute
	await get_tree().process_frame
	
	print("  Hand label text: '%s'" % test_hand.get_label_text())
	
	# Create a Train instance  
	var test_train = train_scene.instantiate()
	add_child(test_train)
	test_train.position = Vector2(50, 200)
	
	# Wait a frame for _ready to execute
	await get_tree().process_frame
	
	print("  Train label text: '%s'" % test_train.get_label_text())
	
	print("\n=== TEST COMPLETE ===")
	print("Expected: Labels should show OS username or fallback name")
	print("Check the Hand and Train labels in the display")
	
	# Add status label to show results
	var status_label = Label.new()
	status_label.text = "Player Naming Test - Check console output and labels"
	status_label.position = Vector2(50, 350)
	status_label.size = Vector2(400, 50)
	add_child(status_label)
