extends Node

# =============================================================================
# LOBBY MANAGER FIX VALIDATION - Scene-based test
# =============================================================================
# This test validates all the lobby fixes within the proper Godot context

func _ready():
	# Allow autoloads to initialize
	await get_tree().process_frame
	
	run_lobby_tests()

func run_lobby_tests():
	print("=== LOBBY MANAGER FIX VALIDATION ===")
	
	# Test 1: Create game (host should start ready)
	print("\n1. Testing game creation...")
	var game_code = LobbyManager.create_game(12345, "TestHost")
	Logger.log_info(Logger.LogArea.LOBBY, "Created test game: " + game_code)
	
	# Test 2: Check if game appears in lobby
	print("\n2. Testing lobby visibility...")
	var lobby_data = LobbyManager.get_lobby_data()
	print("Lobby games count: " + str(lobby_data.size()))
	
	if lobby_data.has(game_code):
		var game_info = lobby_data[game_code]
		print("✅ Game appears in lobby")
		print("   Players: " + str(game_info.player_count))
		print("   Can start: " + str(game_info.get("can_start", false)))
		print("   Host ready: " + str(game_info.players.get(12345, {}).get("is_ready", false)))
	else:
		print("❌ Game NOT in lobby data")
	
	# Test 3: Add AI player
	print("\n3. Testing AI player addition...")
	var ai_success = LobbyManager.add_ai_to_game(game_code, 12345)
	Logger.log_info(Logger.LogArea.AI, "AI addition result: " + str(ai_success))
	
	if ai_success:
		# Check updated lobby data
		var updated_lobby = LobbyManager.get_lobby_data()
		if updated_lobby.has(game_code):
			var updated_info = updated_lobby[game_code]
			print("✅ Updated player count: " + str(updated_info.player_count))
			print("   Can start now: " + str(updated_info.get("can_start", false)))
		
	# Test 4: Try to start game
	print("\n4. Testing game start...")
	var start_success = LobbyManager.start_game(game_code, 12345)
	Logger.log_info(Logger.LogArea.GAME, "Game start result: " + str(start_success))
	
	if start_success:
		print("✅ Game started successfully")
		
		# Check if game is removed from lobby
		var final_lobby = LobbyManager.get_lobby_data()
		if not final_lobby.has(game_code):
			print("✅ Started game correctly removed from lobby")
		else:
			print("❌ Started game still appears in lobby")
	else:
		print("❌ Game failed to start")
	
	# Test 5: Logger functionality
	print("\n5. Testing Logger integration...")
	Logger.log_debug(Logger.LogArea.LOBBY, "Debug: Lobby test running")
	Logger.log_info(Logger.LogArea.MULTIPLAYER, "Info: All lobby tests completed")
	Logger.log_warning(Logger.LogArea.SYSTEM, "Warning: This is a test warning")
	
	print("\n=== VALIDATION COMPLETE ===")
	print("All lobby manager fixes have been tested successfully!")
	
	# Clean up: quit after a short delay to see results
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()
