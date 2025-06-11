extends Node

## Lobby Manager for Mexican Train multiplayer game
## Handles game rooms, codes, and player matchmaking

signal game_created(game_code: String, game_info: Dictionary)
signal game_joined(game_code: String, player_id: int)
signal game_started(game_code: String)
signal lobby_updated(games: Dictionary)

# Game configuration - using GameConfig constants
var MAX_PLAYERS_PER_GAME: int = 8  # Will be set to GameConfig.MAX_PLAYERS in _ready()
const GAME_CODE_LENGTH = 6

# Game rooms storage
var active_games: Dictionary = {}  # game_code -> GameRoom
var player_to_game: Dictionary = {}  # player_id -> game_code

class GameRoom:
	var code: String
	var host_id: int
	var players: Dictionary = {}  # player_id -> player_data
	var ai_players: Dictionary = {}  # ai_id -> ai_data
	var is_started: bool = false
	var max_players: int = 8  # Will be updated in _ready()
	var created_time: float
	
	func _init(game_code: String, host_player_id: int, host_name: String):
		code = game_code
		host_id = host_player_id
		created_time = Time.get_time_dict_from_system()["unix"]
		
		# Add host as first player
		players[host_player_id] = {
			"name": host_name,
			"is_host": true,
			"is_ai": false,
			"is_ready": false
		}
	
	func add_player(player_id: int, player_name: String) -> bool:
		if get_total_player_count() >= max_players:
			return false
		
		players[player_id] = {
			"name": player_name,
			"is_host": false,
			"is_ai": false,
			"is_ready": false
		}
		return true
	
	func remove_player(player_id: int) -> void:
		players.erase(player_id)
		
		# If host left, transfer to another player or close game
		if player_id == host_id and players.size() > 0:
			host_id = players.keys()[0]
			players[host_id].is_host = true
	
	func add_ai_player(ai_name: String) -> int:
		if get_total_player_count() >= max_players:
			return -1
		
		var ai_id = generate_ai_id()
		ai_players[ai_id] = {
			"name": ai_name,
			"is_host": false,
			"is_ai": true,
			"is_ready": true
		}
		return ai_id
	
	func get_total_player_count() -> int:
		return players.size() + ai_players.size()
	
	func is_full() -> bool:
		return get_total_player_count() >= max_players
	
	func can_start() -> bool:
		# Need at least 2 players (human or AI) and all humans ready
		if get_total_player_count() < 2:
			return false
		
		for player_data in players.values():
			if not player_data.is_ready:
				return false
		
		return true
	
	func get_all_players() -> Dictionary:
		var all_players = {}
		all_players.merge(players)
		all_players.merge(ai_players)
		return all_players
	
	func generate_ai_id() -> int:
		# Generate negative IDs for AI players to avoid conflicts
		return -(ai_players.size() + 1000)

func _ready() -> void:
	# Sync with GameConfig values
	MAX_PLAYERS_PER_GAME = GameConfig.MAX_PLAYERS
	print("LobbyManager initialized - Max players per game: %d" % MAX_PLAYERS_PER_GAME)

## Create a new game room
func create_game(host_id: int, host_name: String) -> String:
	var game_code = generate_game_code()
	var game_room = GameRoom.new(game_code, host_id, host_name)
	
	active_games[game_code] = game_room
	player_to_game[host_id] = game_code
	
	var game_info = get_game_info(game_code)
	game_created.emit(game_code, game_info)
	lobby_updated.emit(get_lobby_data())
	
	print("Game created: %s by %s (ID: %d)" % [game_code, host_name, host_id])
	return game_code

## Join an existing game with code
func join_game(game_code: String, player_id: int, player_name: String) -> bool:
	if not active_games.has(game_code):
		print("Game code not found: %s" % game_code)
		return false
	
	var game_room = active_games[game_code]
	if game_room.is_started:
		print("Game already started: %s" % game_code)
		return false
	
	if game_room.is_full():
		print("Game is full: %s" % game_code)
		return false
	
	# Remove player from previous game if any
	leave_current_game(player_id)
	
	if game_room.add_player(player_id, player_name):
		player_to_game[player_id] = game_code
		game_joined.emit(game_code, player_id)
		lobby_updated.emit(get_lobby_data())
		print("Player %s joined game %s" % [player_name, game_code])
		return true
	
	return false

## Leave current game
func leave_current_game(player_id: int) -> bool:
	if not player_to_game.has(player_id):
		return false
	
	var game_code = player_to_game[player_id]
	var game_room = active_games.get(game_code)
	
	if game_room:
		game_room.remove_player(player_id)
		player_to_game.erase(player_id)
		
		# Close game if no players left
		if game_room.players.size() == 0:
			active_games.erase(game_code)
		
		lobby_updated.emit(get_lobby_data())
		print("Player %d left game %s" % [player_id, game_code])
		return true
	
	return false

## Add AI player to game
func add_ai_to_game(game_code: String, requester_id: int) -> bool:
	var game_room = active_games.get(game_code)
	if not game_room:
		return false
	
	# Only host can add AI players
	if requester_id != game_room.host_id:
		return false
	
	var ai_count = game_room.ai_players.size()
	var ai_name = "AI Player %d" % (ai_count + 1)
	var ai_id = game_room.add_ai_player(ai_name)
	
	if ai_id != -1:
		lobby_updated.emit(get_lobby_data())
		print("AI player added to game %s: %s (ID: %d)" % [game_code, ai_name, ai_id])
		return true
	
	return false

## Set player ready status
func set_player_ready(player_id: int, is_ready: bool) -> bool:
	var game_code = player_to_game.get(player_id)
	if not game_code:
		return false
	
	var game_room = active_games.get(game_code)
	if not game_room or not game_room.players.has(player_id):
		return false
	
	game_room.players[player_id].is_ready = is_ready
	lobby_updated.emit(get_lobby_data())
	print("Player %d ready status: %s" % [player_id, is_ready])
	return true

## Start a game (host only)
func start_game(game_code: String, requester_id: int) -> bool:
	var game_room = active_games.get(game_code)
	if not game_room:
		return false
	
	# Only host can start
	if requester_id != game_room.host_id:
		return false
	
	if not game_room.can_start():
		return false
	
	game_room.is_started = true
	game_started.emit(game_code)
	print("Game started: %s" % game_code)
	return true

## Get lobby data for display
func get_lobby_data() -> Dictionary:
	var lobby_data = {}
	
	for game_code in active_games:
		var game_room = active_games[game_code]
		if not game_room.is_started:  # Only show non-started games in lobby
			lobby_data[game_code] = get_game_info(game_code)
	
	return lobby_data

## Get detailed game information
func get_game_info(game_code: String) -> Dictionary:
	var game_room = active_games.get(game_code)
	if not game_room:
		return {}
	
	return {
		"code": game_code,
		"host_name": game_room.players[game_room.host_id].name,
		"player_count": game_room.get_total_player_count(),
		"max_players": game_room.max_players,
		"is_full": game_room.is_full(),
		"can_start": game_room.can_start(),
		"is_started": game_room.is_started,
		"players": game_room.get_all_players()
	}

## Get game room by code
func get_game_room(game_code: String) -> GameRoom:
	return active_games.get(game_code)

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

## Cleanup old empty games (call periodically)
func cleanup_empty_games() -> void:
	var to_remove = []
	var current_time = Time.get_time_dict_from_system()["unix"]
	
	for game_code in active_games:
		var game_room = active_games[game_code]
		
		# Remove games with no players older than 5 minutes
		if game_room.players.size() == 0 and (current_time - game_room.created_time) > 300:
			to_remove.append(game_code)
	
	for game_code in to_remove:
		active_games.erase(game_code)
		print("Cleaned up empty game: %s" % game_code)
	
	if to_remove.size() > 0:
		lobby_updated.emit(get_lobby_data())
