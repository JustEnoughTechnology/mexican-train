extends Node

## Network Manager for Mexican Train multiplayer game
## Handles server/client connections, lobby system, and game coordination

signal player_connected(peer_id: int, player_name: String)
signal player_disconnected(peer_id: int)
signal game_state_updated(state: Dictionary)
signal lobby_updated(lobby_data: Dictionary)
signal game_created(game_code: String)
signal game_joined(game_code: String)
signal game_started(game_code: String)

# Network configuration
const MAX_PLAYERS = 8
const DEFAULT_PORT = 9957

# Game state
var is_server: bool = false  # True if this is the central server
var network_connected: bool = false
var local_player_id: int = 0
var players: Dictionary = {}  # peer_id -> player_data
var current_game_code: String = ""

# Multiplayer peer
var multiplayer_peer: MultiplayerPeer

func _ready() -> void:
	# Connect multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

## Start as central server (handles lobby and all games)
func start_server(port: int = DEFAULT_PORT) -> bool:
	multiplayer_peer = ENetMultiplayerPeer.new()
	var error = multiplayer_peer.create_server(port, 64)  # Support more connections for lobby
	
	if error == OK:
		multiplayer.multiplayer_peer = multiplayer_peer
		is_server = true
		network_connected = true
		local_player_id = 1
		
		# Connect lobby signals to the autoloaded LobbyManager
		LobbyManager.game_created.connect(_on_lobby_game_created)
		LobbyManager.game_joined.connect(_on_lobby_game_joined)
		LobbyManager.game_started.connect(_on_lobby_game_started)
		LobbyManager.lobby_updated.connect(_on_lobby_updated)
		
		Logger.log_info(Logger.LogArea.NETWORK, "Server started successfully on port %d" % port)
		return true
	else:
		Logger.log_error(Logger.LogArea.NETWORK, "Failed to start server: %s" % error)
		return false

## Connect to server as client
func connect_to_server(address: String, port: int = DEFAULT_PORT) -> bool:
	multiplayer_peer = ENetMultiplayerPeer.new()
	var error = multiplayer_peer.create_client(address, port)
	
	if error == OK:
		multiplayer.multiplayer_peer = multiplayer_peer
		is_server = false
		
		Logger.log_info(Logger.LogArea.NETWORK, "Attempting to connect to server at %s:%d" % [address, port])
		return true
	else:
		Logger.log_error(Logger.LogArea.NETWORK, "Failed to connect to server: %s" % error)
		return false

## Create a new game (client request to server)
func create_game() -> void:
	if not network_connected or is_server:
		return
	
	var player_name_util = preload("res://scripts/util/player_name_util.gd")
	var player_name = player_name_util.get_player_name()
	rpc_id(1, "_request_create_game", player_name)

## Join a game with code (client request to server)
func join_game_with_code(game_code: String) -> void:
	if not network_connected or is_server:
		return
	
	var player_name_util = preload("res://scripts/util/player_name_util.gd")
	var player_name = player_name_util.get_player_name()
	rpc_id(1, "_request_join_game", game_code, player_name)

## Request lobby data (client request to server)
func request_lobby_data() -> void:
	if not network_connected or is_server:
		return
	
	rpc_id(1, "_request_lobby_data")

## Add AI player to current game (client request to server)
func add_ai_player() -> void:
	if not network_connected or is_server or current_game_code.is_empty():
		return
	
	rpc_id(1, "_request_add_ai", current_game_code)

## Set ready status (client request to server)
func set_ready_status(is_ready: bool) -> void:
	if not network_connected or is_server:
		return
	
	rpc_id(1, "_request_set_ready", is_ready)

## Start current game (client request to server)
func start_current_game() -> void:
	if not network_connected or is_server or current_game_code.is_empty():
		return
	
	rpc_id(1, "_request_start_game", current_game_code)

## Disconnect from server
func disconnect_from_server() -> void:
	if multiplayer_peer:
		multiplayer_peer.close()
	
	multiplayer.multiplayer_peer = null
	network_connected = false
	local_player_id = 0
	players.clear()
	current_game_code = ""
	Logger.log_info(Logger.LogArea.NETWORK, "Disconnected from server")

## Check if server is currently running
func is_server_running() -> bool:
	return is_server and network_connected and multiplayer_peer != null

## Get number of connected peers (for server monitoring)
func get_connected_peer_count() -> int:
	if not is_server or not multiplayer_peer:
		return 0
	return multiplayer.get_peers().size()

# Server-side lobby management RPCs
@rpc("any_peer", "call_local", "reliable")
func _request_create_game(player_name: String) -> void:
	if not is_server:
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	var game_code = LobbyManager.create_game(sender_id, player_name)
	
	# Send game code back to creator
	rpc_id(sender_id, "_receive_game_created", game_code)

@rpc("any_peer", "call_local", "reliable")
func _request_join_game(game_code: String, player_name: String) -> void:
	if not is_server:
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	var success = LobbyManager.join_game(game_code, sender_id, player_name)
	
	# Send join result back to player
	rpc_id(sender_id, "_receive_join_result", game_code, success)

@rpc("any_peer", "call_local", "reliable")
func _request_lobby_data() -> void:
	if not is_server:
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	var lobby_data = LobbyManager.get_lobby_data()
	
	# Send lobby data back to requester
	rpc_id(sender_id, "_receive_lobby_data", lobby_data)

@rpc("any_peer", "call_local", "reliable")
func _request_add_ai(game_code: String) -> void:
	if not is_server:
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	var success = LobbyManager.add_ai_to_game(game_code, sender_id)
	
	# Send result back to requester
	rpc_id(sender_id, "_receive_ai_add_result", success)

@rpc("any_peer", "call_local", "reliable")
func _request_set_ready(is_ready: bool) -> void:
	if not is_server:
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	var success = LobbyManager.set_player_ready(sender_id, is_ready)
	
	# Send result back to requester
	rpc_id(sender_id, "_receive_ready_result", success)

@rpc("any_peer", "call_local", "reliable")
func _request_start_game(game_code: String) -> void:
	if not is_server:
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	var success = LobbyManager.start_game(game_code, sender_id)
	
	# Send result back to requester
	rpc_id(sender_id, "_receive_start_result", success)

# Client-side response RPCs
@rpc("any_peer", "call_local", "reliable")
func _receive_game_created(game_code: String) -> void:
	current_game_code = game_code
	game_created.emit(game_code)
	Logger.log_info(Logger.LogArea.MULTIPLAYER, "Game created with code: %s" % game_code)

@rpc("any_peer", "call_local", "reliable")
func _receive_join_result(game_code: String, success: bool) -> void:
	if success:
		current_game_code = game_code
		game_joined.emit(game_code)
		Logger.log_info(Logger.LogArea.MULTIPLAYER, "Successfully joined game: %s" % game_code)
	else:
		Logger.log_warning(Logger.LogArea.MULTIPLAYER, "Failed to join game: %s" % game_code)

@rpc("any_peer", "call_local", "reliable")
func _receive_lobby_data(lobby_data: Dictionary) -> void:
	lobby_updated.emit(lobby_data)

@rpc("any_peer", "call_local", "reliable")
func _receive_ai_add_result(success: bool) -> void:
	if success:
		Logger.log_info(Logger.LogArea.AI, "AI player added successfully")
	else:
		Logger.log_warning(Logger.LogArea.AI, "Failed to add AI player")

@rpc("any_peer", "call_local", "reliable")
func _receive_ready_result(success: bool) -> void:
	if success:
		Logger.log_debug(Logger.LogArea.MULTIPLAYER, "Ready status updated")
	else:
		Logger.log_warning(Logger.LogArea.MULTIPLAYER, "Failed to update ready status")

@rpc("any_peer", "call_local", "reliable")
func _receive_start_result(success: bool) -> void:
	if success:
		Logger.log_info(Logger.LogArea.GAME, "Game start request successful")
	else:
		Logger.log_warning(Logger.LogArea.GAME, "Failed to start game")

# Lobby signal handlers (server-side)
func _on_lobby_game_created(game_code: String, _game_info: Dictionary) -> void:
	Logger.log_info(Logger.LogArea.LOBBY, "Game created - %s" % game_code)

func _on_lobby_game_joined(game_code: String, player_id: int) -> void:
	Logger.log_info(Logger.LogArea.LOBBY, "Player %d joined game %s" % [player_id, game_code])

func _on_lobby_game_started(game_code: String) -> void:
	Logger.log_info(Logger.LogArea.LOBBY, "Game started - %s" % game_code)
	# Notify all players in the game
	var game_room = LobbyManager.get_game_room(game_code)
	if game_room:
		for player_id in game_room.get_all_players():
			if player_id > 0:  # Skip AI players (negative IDs)
				rpc_id(player_id, "_receive_game_started", game_code)

func _on_lobby_updated(lobby_data: Dictionary) -> void:
	# Emit the lobby_updated signal locally
	lobby_updated.emit(lobby_data)
	# Broadcast lobby update to all connected clients
	rpc("_receive_lobby_data", lobby_data)

@rpc("any_peer", "call_local", "reliable")
func _receive_game_started(game_code: String) -> void:
	current_game_code = game_code
	game_started.emit(game_code)
	Logger.log_info(Logger.LogArea.GAME, "Game started: %s" % game_code)

# Network event handlers
func _on_peer_connected(peer_id: int) -> void:
	Logger.log_info(Logger.LogArea.NETWORK, "Peer connected: %d" % peer_id)
	
	if is_server:
		# Get player name from the connected peer if available
		var player_name = "Player %d" % peer_id  # Default name
		players[peer_id] = {"name": player_name}
		player_connected.emit(peer_id, player_name)

func _on_peer_disconnected(peer_id: int) -> void:
	Logger.log_info(Logger.LogArea.NETWORK, "Peer disconnected: %d" % peer_id)
	
	if is_server:
		# Remove player from their current game
		LobbyManager.leave_current_game(peer_id)
	
	# Emit the signal to notify other systems
	player_disconnected.emit(peer_id)

func _on_connected_to_server() -> void:
	Logger.log_info(Logger.LogArea.NETWORK, "Connected to server")
	network_connected = true
	local_player_id = multiplayer.get_unique_id()
	
	# Request current lobby data
	request_lobby_data()

func _on_connection_failed() -> void:
	Logger.log_error(Logger.LogArea.NETWORK, "Failed to connect to server")
	disconnect_from_server()

func _on_server_disconnected() -> void:
	Logger.log_info(Logger.LogArea.NETWORK, "Server disconnected")
	disconnect_from_server()

# Game synchronization RPCs (for actual gameplay)
@rpc("any_peer", "call_local", "reliable")
func sync_game_state(state: Dictionary) -> void:
	game_state_updated.emit(state)

@rpc("any_peer", "call_local", "reliable") 
func sync_domino_action(action: String, data: Dictionary) -> void:
	EventBus.emit_signal("network_domino_action", action, data)

@rpc("any_peer", "call_local", "reliable")
func sync_turn_change(new_active_player_id: int) -> void:
	EventBus.emit_signal("turn_changed", new_active_player_id)
