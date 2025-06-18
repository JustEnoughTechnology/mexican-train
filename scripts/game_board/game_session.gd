extends Node
class_name GameSession

## Game Session state for a single Mexican Train game instance
## Manages the state of one specific game room/match

signal turn_changed(player_id: int)
signal game_state_updated()

# Current game instance state
var game_id: String = ""
var current_player: Player
var current_turn_player_id: int = 0
var players: Array[Player] = []
var is_game_active: bool = false
var turn_number: int = 0

# Game round state
var current_round: int = 0
var starting_domino_value: int = 12  # Start with 12s, then 11s, etc.

# Network state for this game instance
var is_multiplayer_game: bool = false
var game_host_id: int = 0

func _init(p_game_id: String = "") -> void:
	game_id = p_game_id

func set_multiplayer_mode(enabled: bool, host_id: int = 0) -> void:
	"""Configure this game session for multiplayer mode"""
	is_multiplayer_game = enabled
	game_host_id = host_id
	Logger.log_info(Logger.LogArea.GAME, "Game %s - Multiplayer mode: %s (Host ID: %d)" % [game_id, enabled, host_id])

func set_current_turn_player(player_id: int) -> void:
	"""Set the currently active player for this game session"""
	current_turn_player_id = player_id
	turn_changed.emit(player_id)
	Logger.log_info(Logger.LogArea.GAME, "Game %s - Turn changed to player ID: %d" % [game_id, player_id])

func add_player(player: Player) -> void:
	"""Add a player to this game session"""
	if players.size() < GameConfig.MAX_PLAYERS:
		players.append(player)
		Logger.log_info(Logger.LogArea.GAME, "Game %s - Player added: %s (Total: %d)" % [game_id, player.name, players.size()])
		game_state_updated.emit()

func remove_player(player: Player) -> void:
	"""Remove a player from this game session"""
	var index = players.find(player)
	if index >= 0:
		players.remove_at(index)
		Logger.log_info(Logger.LogArea.GAME, "Game %s - Player removed: %s (Remaining: %d)" % [game_id, player.name, players.size()])
		game_state_updated.emit()

func start_game() -> void:
	"""Start this game session"""
	if players.size() >= 2:
		is_game_active = true
		turn_number = 0
		current_round = 1
		starting_domino_value = GameConfig.MAX_DOTS
		Logger.log_info(Logger.LogArea.GAME, "Game %s started with %d players" % [game_id, players.size()])
		game_state_updated.emit()

func end_game() -> void:
	"""End this game session"""
	is_game_active = false
	Logger.log_info(Logger.LogArea.GAME, "Game %s ended" % game_id)
	game_state_updated.emit()

func get_game_state() -> Dictionary:
	"""Get the current state of this game session for network sync"""
	return {
		"game_id": game_id,
		"is_active": is_game_active,
		"current_turn_player_id": current_turn_player_id,
		"turn_number": turn_number,
		"current_round": current_round,
		"starting_domino_value": starting_domino_value,
		"player_count": players.size(),
		"is_multiplayer": is_multiplayer_game,
		"host_id": game_host_id
	}
