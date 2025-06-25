extends Control

## Server Launcher for Mexican Train
## Handles starting the central server and displaying game state

@onready var server_status_label = $VBox/ServerStatus
@onready var lobby_info_label = $VBox/LobbyInfo
@onready var games_list = $VBox/ScrollContainer/GamesList
@onready var start_server_button = $VBox/ButtonContainer/StartServerButton
@onready var stop_server_button = $VBox/ButtonContainer/StopServerButton

var network_manager: NetworkManager
var update_timer: Timer
var last_server_state: bool = false  # Track the last known server state

func _ready() -> void:
	get_window().title = "Mexican Train - Central Server"
	
	# Use the autoload singleton instead of creating a new instance
	network_manager = NetworkManager
	
	# Connect signals
	network_manager.lobby_updated.connect(_on_lobby_updated)
	network_manager.player_disconnected.connect(_on_player_disconnected)
	
	# Setup UI
	stop_server_button.disabled = true
	start_server_button.pressed.connect(_on_start_server)
	stop_server_button.pressed.connect(_on_stop_server)
	
	# Setup update timer for periodic lobby updates
	update_timer = Timer.new()
	update_timer.wait_time = 2.0
	update_timer.timeout.connect(_update_server_info)
	add_child(update_timer)
	
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
		print("Mexican Train server started successfully")
	else:
		server_status_label.text = "Server Status: FAILED TO START"
		server_status_label.modulate = Color.RED
		print("Failed to start Mexican Train server")

func _on_stop_server() -> void:
	network_manager.disconnect_from_server()
	server_status_label.text = "Server Status: STOPPED"
	server_status_label.modulate = Color.GRAY
	start_server_button.disabled = false
	stop_server_button.disabled = true
	update_timer.stop()
	_clear_games_display()
	print("Mexican Train server stopped")

func _on_lobby_updated(lobby_data: Dictionary) -> void:
	_update_games_display(lobby_data)

func _on_player_disconnected(_peer_id: int) -> void:
	# When players disconnect, update the server info
	# This also handles when the server itself is stopped
	_update_server_info()

func _update_server_info() -> void:
	# Check if the server is actually running
	if network_manager.is_server_running():
		var lobby_data = LobbyManager.get_lobby_data()
		lobby_info_label.text = "Active Games: %d" % lobby_data.size()
		_update_games_display(lobby_data)
		
		# Ensure server status label reflects running state
		if server_status_label.text.contains("STOPPED"):
			server_status_label.text = "Server Status: RUNNING on port %d" % NetworkManager.DEFAULT_PORT
			server_status_label.modulate = Color.GREEN
			start_server_button.disabled = true
			stop_server_button.disabled = false
			update_timer.start()
	else:
		lobby_info_label.text = "Server not running"
		
		# Update server status label to reflect stopped state
		server_status_label.text = "Server Status: STOPPED"
		server_status_label.modulate = Color.GRAY
		start_server_button.disabled = false
		stop_server_button.disabled = true
		update_timer.stop()
		_clear_games_display()
		
		print("Server status updated to STOPPED")

func _update_games_display(lobby_data: Dictionary) -> void:
	# Clear existing game info
	_clear_games_display()
	
	if lobby_data.is_empty():
		var no_games_label = Label.new()
		no_games_label.text = "No active games"
		no_games_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		games_list.add_child(no_games_label)
		return
	
	# Display each game
	for game_code in lobby_data:
		var game_info = lobby_data[game_code]
		var game_panel = _create_game_panel(game_code, game_info)
		games_list.add_child(game_panel)

func _create_game_panel(game_code: String, game_info: Dictionary) -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(400, 120)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	
	# Game code and host
	var title_label = Label.new()
	title_label.text = "Game Code: %s (Host: %s)" % [game_code, game_info.get("host_name", "Unknown")]
	title_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title_label)
	
	# Player count and status
	var status_label = Label.new()
	var player_count = game_info.get("player_count", 0)
	var max_players = game_info.get("max_players", 8)
	var can_start = game_info.get("can_start", false)
	status_label.text = "Players: %d/%d | Can Start: %s" % [player_count, max_players, "Yes" if can_start else "No"]
	vbox.add_child(status_label)
	
	# Player list
	var players_info = game_info.get("players", {})
	var players_text = "Players: "
	var player_names = []
	for player_data in players_info.values():
		var player_name = player_data.get("name", "Unknown")
		var ready_status = " (Ready)" if player_data.get("is_ready", false) else " (Not Ready)"
		var ai_status = " [AI]" if player_data.get("is_ai", false) else ""
		player_names.append(player_name + ready_status + ai_status)
	
	players_text += ", ".join(player_names) if player_names.size() > 0 else "None"
	
	var players_label = Label.new()
	players_label.text = players_text
	players_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(players_label)
	
	return panel

func _clear_games_display() -> void:
	for child in games_list.get_children():
		child.queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F5:
				_update_server_info()
			KEY_ESCAPE:
				get_tree().quit()
