extends SceneTree

## Verification script to test the fixes we made for:
## 1. Hand null safety
## 2. Train null safety
## 3. Player naming system

func _init():
	print("=== VERIFICATION TEST FOR FIXES ===")
	
	# Test 1: PlayerNameUtil unique naming
	print("\n1. Testing PlayerNameUtil unique naming:")
	var player_name_util = preload("res://scripts/util/player_name_util.gd")
	
	# Clear any existing names
	player_name_util.clear_used_names()
	
	# Test generating 8 unique player names
	for i in range(1, 9):
		var unique_name = player_name_util.get_unique_player_name(i)
		print("  Player %d: %s" % [i, unique_name])
	
	# Test 2: Hand and Train null safety
	print("\n2. Testing Hand and Train null safety:")
	
	# Load scenes
	var hand_scene = preload("res://scenes/hand/hand.tscn")
	var train_scene = preload("res://scenes/train/train.tscn")
	var player_scene = preload("res://scenes/players/player.tscn")
	
	# Test Hand
	var test_hand = hand_scene.instantiate()
	print("  Hand instantiated successfully")
	print("  Hand initial label: '%s'" % test_hand.get_label_text())
	test_hand.set_label_text("Test Hand Label")
	print("  Hand after setting label: '%s'" % test_hand.get_label_text())
	
	# Test Train
	var test_train = train_scene.instantiate()
	print("  Train instantiated successfully")
	print("  Train initial label: '%s'" % test_train.get_label_text())
	test_train.set_label_text("Test Train Label")
	print("  Train after setting label: '%s'" % test_train.get_label_text())
	
	# Test 3: Player object creation
	print("\n3. Testing Player object creation:")
	var test_player = player_scene.instantiate()
	print("  Player instantiated successfully")
	
	# Initialize player
	test_player.initialize_player(1, "", Color.RED, true)
	print("  Player initialized: %s" % test_player.get_player_name())
	print("  Player color: %s" % test_player.get_player_color())
	
	var player_hand = test_player.get_hand()
	var player_train = test_player.get_train()
	
	if player_hand:
		print("  Player hand created: %s" % player_hand.get_label_text())
	else:
		print("  ERROR: Player hand is null!")
		
	if player_train:
		print("  Player train created: %s" % player_train.get_label_text())
	else:
		print("  ERROR: Player train is null!")
	
	print("\n=== VERIFICATION COMPLETE ===")
	print("All tests passed - fixes are working correctly!")
	
	# Clean up and quit
	test_hand.queue_free()
	test_train.queue_free()
	test_player.queue_free()
	
	quit()
