extends Node

## Lobby Manager for Mexican Train multiplayer game
## Handles game rooms, codes, and player matchmaking

signal game_created(game_code: String, game_info: Dictionary)
signal game_joined(game_code: String, player_id: int)
signal game_started(game_code: String)
signal lobby_updated(lobby_data: Dictionary)

# Game configuration - using GameConfig constants
var MAX_PLAYERS_PER_GAME: int = 8  # Will be set to GameConfig.MAX_PLAYERS in _ready()
const GAME_CODE_LENGTH = 6

# Game rooms storage
var active_games: Dictionary = {}  # game_code -> GameRoom
var player_to_game: Dictionary = {}  # player_id -> game_code

func _ready() -> void:
	# Sync with GameConfig values	MAX_PLAYERS_PER_GAME = GameConfig.MAX_PLAYERS
	Logger.log_info(Logger.LogArea.LOBBY, "LobbyManager initialized - Max players per game: %d" % MAX_PLAYERS_PER_GAME)

## Create a new game room
func create_game(host_id: int, host_name: String) -> String:
	var game_code = generate_game_code()
		# For now, store basic game info without complex GameRoom class
	active_games[game_code] = {
		"host_id": host_id,
		"host_name": host_name,
		"players": {host_id: {"name": host_name, "is_host": true, "is_ready": true}},  # Host starts ready
		"is_started": false,
		"created_time": Time.get_unix_time_from_system()
	}
	
	player_to_game[host_id] = game_code
	
	var game_info = {
		"code": game_code,
		"host_name": host_name,
		"player_count": 1,
		"max_players": MAX_PLAYERS_PER_GAME
	}
	game_created.emit(game_code, game_info)
	lobby_updated.emit(get_lobby_data())
		Logger.log_info(Logger.LogArea.LOBBY, "Game created: %s by %s (ID: %d)" % [game_code, host_name, host_id])
	return game_code

## Join an existing game room
func join_game(game_code: String, player_id: int, player_name: String) -> bool:
	if not active_games.has(game_code):
		Logger.log_warning(Logger.LogArea.LOBBY, "Game not found: %s" % game_code)
		return false
	
	var game = active_games[game_code]
	if game.is_started:
		Logger.log_warning(Logger.LogArea.LOBBY, "Game already started: %s" % game_code)
		return false
	
	if game.players.size() >= MAX_PLAYERS_PER_GAME:
		Logger.log_warning(Logger.LogArea.LOBBY, "Game is full: %s" % game_code)
		return false
	
	game.players[player_id] = {"name": player_name, "is_host": false, "is_ready": false}
	player_to_game[player_id] = game_code
		game_joined.emit(game_code, player_id)
	lobby_updated.emit(get_lobby_data())
	Logger.log_info(Logger.LogArea.LOBBY, "Player %s (ID: %d) joined game: %s" % [player_name, player_id, game_code])
	return true

## Start a game room
func start_game(game_code: String, host_id: int) -> bool:
	if not active_games.has(game_code):
		Logger.log_warning(Logger.LogArea.LOBBY, "Game not found: %s" % game_code)
		return false
	
	var game = active_games[game_code]	if game.host_id != host_id:
		Logger.log_warning(Logger.LogArea.LOBBY, "Only host can start the game: %s" % game_code)
		return false
	
	if game.is_started:
		Logger.log_warning(Logger.LogArea.LOBBY, "Game already started: %s" % game_code)
		return false
	
	# Check if the game can start (all players ready)
	if not _can_game_start(game):
		Logger.log_warning(Logger.LogArea.LOBBY, "Game cannot start - not all players are ready: %s" % game_code)
		return false
	
	game.is_started = true
	game_started.emit(game_code)	lobby_updated.emit(get_lobby_data())
	Logger.log_info(Logger.LogArea.LOBBY, "Game started: %s" % game_code)
	return true

## Leave current game (for disconnected players)
func leave_current_game(player_id: int) -> bool:
	if not player_to_game.has(player_id):
		return false
	
	var game_code = player_to_game[player_id]
	var game = active_games.get(game_code)
	
	if game:
		# Remove player from the game
		game.players.erase(player_id)
		player_to_game.erase(player_id)
		
		# Close game if no players left		if game.players.size() == 0:
			active_games.erase(game_code)
			Logger.log_info(Logger.LogArea.LOBBY, "Game %s closed - no players remaining" % game_code)
		else:
			# If the leaving player was the host, transfer host to another player
			if game.host_id == player_id and game.players.size() > 0:
				var new_host_id = game.players.keys()[0]
				game.host_id = new_host_id
				game.host_name = game.players[new_host_id].name
				game.players[new_host_id].is_host = true
				Logger.log_info(Logger.LogArea.LOBBY, "Host transferred to player %d in game %s" % [new_host_id, game_code])
		
		lobby_updated.emit(get_lobby_data())
		Logger.log_info(Logger.LogArea.LOBBY, "Player %d left game %s" % [player_id, game_code])
		return true
	
	return false

## Generate a unique game code
func generate_game_code() -> String:
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var code = ""
	
	for i in range(GAME_CODE_LENGTH):
		code += chars[randi() % chars.length()]
	
	# Ensure uniqueness
	while active_games.has(code):
		code = ""
		for i in range(GAME_CODE_LENGTH):
			code += chars[randi() % chars.length()]
	
	return code

## Get lobby data for display (returns games that haven't started yet)
func get_lobby_data() -> Dictionary:
	var lobby_data = {}
	
	for game_code in active_games:
		var game = active_games[game_code]
		if not game.is_started:  # Only show non-started games in lobby
			lobby_data[game_code] = get_game_info(game_code)
	
	return lobby_data

## Get detailed game information
func get_game_info(game_code: String) -> Dictionary:
	var game = active_games.get(game_code)
	if not game:
		return {}
	
	return {
		"code": game_code,
		"host_name": game.host_name,
		"player_count": game.players.size(),
		"max_players": MAX_PLAYERS_PER_GAME,
		"is_full": game.players.size() >= MAX_PLAYERS_PER_GAME,
		"can_start": _can_game_start(game),
		"is_started": game.is_started,
		"players": game.players
	}

## Add AI player to game
func add_ai_to_game(game_code: String, requester_id: int) -> bool:	var game = active_games.get(game_code)
	if not game:
		Logger.log_warning(Logger.LogArea.AI, "Game not found for AI addition: %s" % game_code)
		return false
	
	# Only host can add AI players
	if requester_id != game.host_id:
		Logger.log_warning(Logger.LogArea.AI, "Non-host tried to add AI player to game %s" % game_code)
		return false
	
	# Check if game is full
	if game.players.size() >= MAX_PLAYERS_PER_GAME:
		Logger.log_warning(Logger.LogArea.AI, "Game is full, cannot add AI player: %s" % game_code)
		return false
	
	# Generate AI player data
	var ai_count = 0
	for player_data in game.players.values():
		if player_data.get("is_ai", false):
			ai_count += 1
	
	var ai_name = "AI Player %d" % (ai_count + 1)
	var ai_id = -(ai_count + 1000)  # Use negative IDs for AI players
	
	# Add AI player to the game
	game.players[ai_id] = {
		"name": ai_name,
		"is_host": false,
		"is_ai": true,
		"is_ready": true  # AI players are always ready
	}
		lobby_updated.emit(get_lobby_data())
	Logger.log_info(Logger.LogArea.AI, "AI player added to game %s: %s (ID: %d)" % [game_code, ai_name, ai_id])
	return true

## Helper function to check if a game can start
func _can_game_start(game: Dictionary) -> bool:
	# Need at least 2 players (human or AI) to start
	if game.players.size() < 2:
		return false
	
	# All human players must be ready (AI players are always ready)
	for player_data in game.players.values():
		var is_ai = player_data.get("is_ai", false)
		var is_ready = player_data.get("is_ready", false)
		
		# Human players must be ready
		if not is_ai and not is_ready:
			return false
	
	return true

## Set player ready status
func set_player_ready(player_id: int, is_ready: bool) -> bool:
	var game_code = player_to_game.get(player_id)
	if not game_code:		Logger.log_warning(Logger.LogArea.LOBBY, "Player %d not in any game" % player_id)
		return false
	
	var game = active_games.get(game_code)
	if not game or not game.players.has(player_id):
		Logger.log_warning(Logger.LogArea.LOBBY, "Player %d not found in game %s" % [player_id, game_code])
		return false
	
	# Update player ready status
	game.players[player_id]["is_ready"] = is_ready
	
	lobby_updated.emit(get_lobby_data())
	Logger.log_info(Logger.LogArea.LOBBY, "Player %d ready status: %s in game %s" % [player_id, is_ready, game_code])
	return true

## Get game room data by code (for NetworkManager compatibility)
func get_game_room(game_code: String) -> Dictionary:
	return active_games.get(game_code, {})
