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
	# Sync with GameConfig values
	MAX_PLAYERS_PER_GAME = GameConfig.MAX_PLAYERS
	print("LobbyManager initialized - Max players per game: %d" % MAX_PLAYERS_PER_GAME)

## Create a new game room
func create_game(host_id: int, host_name: String) -> String:
	var game_code = generate_game_code()	# For now, store basic game info without complex GameRoom class
	active_games[game_code] = {
		"host_id": host_id,
		"host_name": host_name,
		"players": {host_id: {"name": host_name, "is_host": true}},
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
	
	print("Game created: %s by %s (ID: %d)" % [game_code, host_name, host_id])
	return game_code

## Join an existing game room
func join_game(game_code: String, player_id: int, player_name: String) -> bool:
	if not active_games.has(game_code):
		print("Game not found: %s" % game_code)
		return false
	
	var game = active_games[game_code]
	if game.is_started:
		print("Game already started: %s" % game_code)
		return false
	
	if game.players.size() >= MAX_PLAYERS_PER_GAME:
		print("Game is full: %s" % game_code)
		return false
	
	game.players[player_id] = {"name": player_name, "is_host": false}
	player_to_game[player_id] = game_code
	
	game_joined.emit(game_code, player_id)
	lobby_updated.emit(get_lobby_data())
	print("Player %s (ID: %d) joined game: %s" % [player_name, player_id, game_code])
	return true

## Start a game room
func start_game(game_code: String, host_id: int) -> bool:
	if not active_games.has(game_code):
		print("Game not found: %s" % game_code)
		return false
	
	var game = active_games[game_code]
	if game.host_id != host_id:
		print("Only host can start the game: %s" % game_code)
		return false
	
	if game.is_started:
		print("Game already started: %s" % game_code)
		return false
	
	game.is_started = true
	game_started.emit(game_code)
	lobby_updated.emit(get_lobby_data())
	print("Game started: %s" % game_code)
	return true

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
		"can_start": game.players.size() >= 2,  # Need at least 2 players to start
		"is_started": game.is_started,
		"players": game.players
	}
