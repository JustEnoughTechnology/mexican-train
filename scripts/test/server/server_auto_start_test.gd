extends Control

## Auto-Starting Server Launcher for Mexican Train
## Automatically starts the central server on load and displays game state

@onready var server_status_label = $VBox/ServerStatus
@onready var lobby_info_label = $VBox/LobbyInfo
@onready var games_list = $VBox/ScrollContainer/GamesList
@onready var start_server_button = $VBox/ButtonContainer/StartServerButton
@onready var stop_server_button = $VBox/ButtonContainer/StopServerButton

var network_manager: NetworkManager
var update_timer: Timer
var last_server_state: bool = false
var auto_start_attempted: bool = false

func _ready() -> void:
	get_window().title = "Mexican Train - Auto-Start Server"
	
	# Use the autoload singleton
	network_manager = NetworkManager
	
	# Connect signals
	network_manager.lobby_updated.connect(_on_lobby_updated)
	network_manager.player_disconnected.connect(_on_player_disconnected)
	
	# Setup UI
	start_server_button.pressed.connect(_on_start_server)
	stop_server_button.pressed.connect(_on_stop_server)
	
	# Setup update timer for periodic lobby updates
	update_timer = Timer.new()
	update_timer.wait_time = 2.0
	update_timer.timeout.connect(_update_server_info)
	add_child(update_timer)
	
	# Auto-start the server after a brief delay
	var auto_start_timer = Timer.new()
	auto_start_timer.wait_time = 1.0
	auto_start_timer.one_shot = true
	auto_start_timer.timeout.connect(_auto_start_server)
	add_child(auto_start_timer)
	auto_start_timer.start()
	
	_update_server_info()

func _auto_start_server() -> void:
	if auto_start_attempted:
		return
	
	auto_start_attempted = true
	
	if not network_manager.is_server_running():
		print("🤖 Auto-starting server...")
		server_status_label.text = "Server Status: AUTO-STARTING..."
		server_status_label.modulate = Color.YELLOW
		
		if network_manager.start_server():
			print("✅ Server auto-started successfully!")
			server_status_label.text = "Server Status: AUTO-STARTED on port %d" % NetworkManager.DEFAULT_PORT
			server_status_label.modulate = Color.GREEN
			start_server_button.disabled = true
			stop_server_button.disabled = false
			update_timer.start()
		else:
			print("❌ Failed to auto-start server")
			server_status_label.text = "Server Status: AUTO-START FAILED"
			server_status_label.modulate = Color.RED
	else:
		print("ℹ️ Server already running, skipping auto-start")
		_update_server_info()

func _process(_delta: float) -> void:
	# Monitor server state changes continuously
	var current_server_state = network_manager.is_server_running()
	if current_server_state != last_server_state:
		last_server_state = current_server_state
		_update_server_info()
		print("Server state changed to: %s" % ("RUNNING" if current_server_state else "STOPPED"))

func _on_start_server() -> void:
	if network_manager.start_server():
		server_status_label.text = "Server Status: RUNNING on port %d" % NetworkManager.DEFAULT_PORT
		server_status_label.modulate = Color.GREEN
		start_server_button.disabled = true
		stop_server_button.disabled = false
		update_timer.start()
	else:
		server_status_label.text = "Server Status: FAILED TO START"
		server_status_label.modulate = Color.RED

func _on_stop_server() -> void:
	network_manager.stop_server()
	server_status_label.text = "Server Status: STOPPED"
	server_status_label.modulate = Color.RED
	start_server_button.disabled = false
	stop_server_button.disabled = true
	update_timer.stop()
	
	# Clear displays
	lobby_info_label.text = "No lobby information (server stopped)"
	_clear_games_list()

func _update_server_info() -> void:
	if network_manager.is_server_running():
		server_status_label.text = "Server Status: RUNNING on port %d" % NetworkManager.DEFAULT_PORT
		server_status_label.modulate = Color.GREEN
		start_server_button.disabled = true
		stop_server_button.disabled = false
		
		# Update lobby info
		var lobby_data = ServerAdmin.get_current_lobby_data()
		if lobby_data:
			lobby_info_label.text = "Connected Players: %d\nActive Games: %d" % [
				lobby_data.players.size(),
				lobby_data.games.size()
			]
		else:
			lobby_info_label.text = "Lobby: No data available"
		
		# Update games list
		_update_games_list()
		
		if not update_timer.is_stopped():
			update_timer.stop()
		update_timer.start()
	else:
		server_status_label.text = "Server Status: STOPPED"
		server_status_label.modulate = Color.RED
		start_server_button.disabled = false
		stop_server_button.disabled = true
		lobby_info_label.text = "No lobby information (server stopped)"
		_clear_games_list()
		update_timer.stop()

func _update_games_list() -> void:
	_clear_games_list()
	
	var lobby_data = ServerAdmin.get_current_lobby_data()
	if not lobby_data or lobby_data.games.is_empty():
		var no_games_label = Label.new()
		no_games_label.text = "No active games"
		no_games_label.modulate = Color.GRAY
		games_list.add_child(no_games_label)
		return
	
	for game_id in lobby_data.games:
		var game_data = lobby_data.games[game_id]
		var game_info = Label.new()
		game_info.text = "Game %s: %d players" % [game_id, game_data.players.size()]
		game_info.modulate = Color.WHITE
		games_list.add_child(game_info)

func _clear_games_list() -> void:
	for child in games_list.get_children():
		child.queue_free()

func _on_lobby_updated() -> void:
	_update_server_info()

func _on_player_disconnected(player_id: int) -> void:
	print("Player %d disconnected" % player_id)
	_update_server_info()
