extends SceneTree

# Test script to verify Player object creation with unique names

func _ready():
	print("=== Testing Player Object Creation with Unique Names ===")
	
	# Test creating multiple Player objects
	var players: Array[Player] = []
	print("\n--- Creating 8 Player objects ---")
	for i in range(8):
		var player = Player.new()
		player.initialize_player(i + 1, "", Color.WHITE, true)  # player_number, name, color, is_human
		players.append(player)
		print("Player %d: %s (Color: %s)" % [player.player_number, player.player_name, player.player_color])
	
	print("\n--- Verifying Unique Names ---")
	var name_counts = {}
	for player in players:
		if player.player_name in name_counts:
			name_counts[player.player_name] += 1
		else:
			name_counts[player.player_name] = 1
	
	var duplicates_found = false
	for name in name_counts:
		if name_counts[name] > 1:
			print("ERROR: Duplicate name found: %s (count: %d)" % [name, name_counts[name]])
			duplicates_found = true
	
	if not duplicates_found:
		print("SUCCESS: All player names are unique!")
		print("\n--- Testing Player Name Util directly ---")
	PlayerNameUtil.clear_used_names()  # Reset for clean test
	
	var direct_names = []
	for i in range(8):
		var name = PlayerNameUtil.get_unique_player_name()
		direct_names.append(name)
		print("Direct name %d: %s" % [i + 1, name])
	
	# Check for duplicates in direct names
	var direct_name_counts = {}
	for name in direct_names:
		if name in direct_name_counts:
			direct_name_counts[name] += 1
		else:
			direct_name_counts[name] = 1
	
	var direct_duplicates_found = false
	for name in direct_name_counts:
		if direct_name_counts[name] > 1:
			print("ERROR: Duplicate direct name found: %s (count: %d)" % [name, direct_name_counts[name]])
			direct_duplicates_found = true
	
	if not direct_duplicates_found:
		print("SUCCESS: All direct names are unique!")
	
	print("\n=== Test Complete ===")
	quit()
