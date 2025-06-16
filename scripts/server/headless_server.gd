extends Node

## Headless Server Launcher for Mexican Train
## Run with: godot --headless scenes/server/headless_server.tscn
## Or add command line arguments for configuration

var network_manager: NetworkManager
var server_port: int = NetworkManager.DEFAULT_PORT
var max_players: int = 32

func _ready() -> void:
	Logger.log_info(Logger.LogArea.SYSTEM, "=== Mexican Train Headless Server ===")
	Logger.log_info(Logger.LogArea.SYSTEM, "Starting server initialization...")
	
	# Parse command line arguments
	_parse_command_line_args()
	
	# Use the autoload singleton
	network_manager = NetworkManager
	
	# Connect to server events
	network_manager.lobby_updated.connect(_on_lobby_updated)
	network_manager.player_connected.connect(_on_player_connected)
	network_manager.player_disconnected.connect(_on_player_disconnected)
	
	# Start the server
	_start_server()
	
	# Setup graceful shutdown
	_setup_shutdown_handling()

func _parse_command_line_args() -> void:
	var args = OS.get_cmdline_args()
	
	for i in range(args.size()):
		var arg = args[i]
		match arg:
			"--port":				if i + 1 < args.size():
					server_port = args[i + 1].to_int()
					if server_port <= 0:
						server_port = NetworkManager.DEFAULT_PORT
					Logger.log_info(Logger.LogArea.SYSTEM, "Port set to: %d" % server_port)
			"--max-players":				if i + 1 < args.size():
					max_players = args[i + 1].to_int()
					if max_players <= 0:
						max_players = 32
					Logger.log_info(Logger.LogArea.SYSTEM, "Max players set to: %d" % max_players)
			"--help":
				_print_help()
				get_tree().quit(0)

func _print_help() -> void:
	Logger.log_info(Logger.LogArea.SYSTEM, "")
	Logger.log_info(Logger.LogArea.SYSTEM, "Mexican Train Headless Server")
	Logger.log_info(Logger.LogArea.SYSTEM, "Usage: godot --headless scenes/server/headless_server.tscn [options]")
	Logger.log_info(Logger.LogArea.SYSTEM, "")
	Logger.log_info(Logger.LogArea.SYSTEM, "Options:")
	Logger.log_info(Logger.LogArea.SYSTEM, "  --port <number>        Set server port (default: %d)" % NetworkManager.DEFAULT_PORT)
	Logger.log_info(Logger.LogArea.SYSTEM, "  --max-players <number> Set maximum players (default: 32)")
	Logger.log_info(Logger.LogArea.SYSTEM, "  --help                 Show this help message")
	Logger.log_info(Logger.LogArea.SYSTEM, "")
	Logger.log_info(Logger.LogArea.SYSTEM, "Examples:")
	Logger.log_info(Logger.LogArea.SYSTEM, "  godot --headless scenes/server/headless_server.tscn")
	Logger.log_info(Logger.LogArea.SYSTEM, "  godot --headless scenes/server/headless_server.tscn --port 9000")
	Logger.log_info(Logger.LogArea.SYSTEM, "  godot --headless scenes/server/headless_server.tscn --port %d --max-players 16" % NetworkManager.DEFAULT_PORT)
	Logger.log_info(Logger.LogArea.SYSTEM, "")

func _start_server() -> void:
	Logger.log_info(Logger.LogArea.NETWORK, "Attempting to start server on port %d..." % server_port)
	
	if network_manager.start_server(server_port):
		Logger.log_info(Logger.LogArea.NETWORK, "✅ Server started successfully!")
		Logger.log_info(Logger.LogArea.SYSTEM, "   Port: %d" % server_port)
		Logger.log_info(Logger.LogArea.SYSTEM, "   Max Players: %d" % max_players)
		Logger.log_info(Logger.LogArea.SYSTEM, "   Server is ready for connections.")
		Logger.log_info(Logger.LogArea.SYSTEM, "")
		Logger.log_info(Logger.LogArea.SYSTEM, "To connect clients, use server address: 127.0.0.1:%d" % server_port)
		Logger.log_info(Logger.LogArea.SYSTEM, "Press Ctrl+C to stop the server")
		Logger.log_info(Logger.LogArea.SYSTEM, "")
		
		# Start periodic status updates
		var timer = Timer.new()
		timer.wait_time = 30.0  # Every 30 seconds
		timer.timeout.connect(_print_status)
		timer.autostart = true
		add_child(timer)
	else:
		Logger.log_error(Logger.LogArea.NETWORK, "❌ Failed to start server on port %d" % server_port)
		Logger.log_error(Logger.LogArea.SYSTEM, "   Make sure the port is not already in use.")
		Logger.log_error(Logger.LogArea.SYSTEM, "   Try a different port with --port <number>")
		get_tree().quit(1)

func _setup_shutdown_handling() -> void:
	# Handle graceful shutdown on exit
	get_tree().auto_accept_quit = false
	get_tree().quit_on_go_back = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_shutdown_server()

func _shutdown_server() -> void:
	Logger.log_info(Logger.LogArea.SYSTEM, "")
	Logger.log_info(Logger.LogArea.SYSTEM, "Shutting down server...")
	
	if network_manager and network_manager.is_server_running():
		# Notify all connected players
		var connected_players = network_manager.get_connected_players()
		if connected_players.size() > 0:
			Logger.log_info(Logger.LogArea.NETWORK, "Disconnecting %d players..." % connected_players.size())
		
		network_manager.stop_server()
		Logger.log_info(Logger.LogArea.NETWORK, "✅ Server stopped successfully")
	
	Logger.log_info(Logger.LogArea.SYSTEM, "Goodbye!")
	get_tree().quit(0)

func _on_player_connected(player_id: int, player_info: Dictionary) -> void:
	var player_name = player_info.get("name", "Unknown")
	Logger.log_info(Logger.LogArea.NETWORK, "✅ Player connected: %s (ID: %d)" % [player_name, player_id])
	_print_current_stats()

func _on_player_disconnected(player_id: int) -> void:
	Logger.log_info(Logger.LogArea.NETWORK, "❌ Player disconnected (ID: %d)" % player_id)
	_print_current_stats()

func _on_lobby_updated() -> void:
	# Called when lobby state changes (games created/ended, etc.)
	pass

func _print_status() -> void:
	Logger.log_info(Logger.LogArea.SYSTEM, "--- Server Status Update ---")
	_print_current_stats()
	Logger.log_info(Logger.LogArea.SYSTEM, "")

func _print_current_stats() -> void:
	if not network_manager:
		return
		
	var connected_players = network_manager.players
	var active_games = LobbyManager.active_games
	
	Logger.log_info(Logger.LogArea.SYSTEM, "   Connected Players: %d/%d" % [connected_players.size(), max_players])
	Logger.log_info(Logger.LogArea.SYSTEM, "   Active Games: %d" % active_games.size())
	
	if connected_players.size() > 0:
		Logger.log_info(Logger.LogArea.SYSTEM, "   Players online:")
		for player_id in connected_players:
			var player_info = connected_players[player_id]
			var player_name = player_info.get("name", "Unknown")
			Logger.log_info(Logger.LogArea.SYSTEM, "     - %s (ID: %d)" % [player_name, player_id])

func _input(event: InputEvent) -> void:
	# Handle Ctrl+C equivalent for graceful shutdown
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or (event.ctrl_pressed and event.keycode == KEY_C):
			_shutdown_server()
