extends Control

## Client Lobby for Mexican Train
## Allows players to connect, create games, join games with codes, and manage game rooms

@onready var connection_panel = $ConnectionPanel
@onready var lobby_panel = $LobbyPanel
@onready var game_room_panel = $GameRoomPanel

# Connection panel elements
@onready var server_address_input = $ConnectionPanel/VBox/ServerAddressInput
@onready var connect_button = $ConnectionPanel/VBox/ConnectButton
@onready var connection_status = $ConnectionPanel/VBox/ConnectionStatus

# Lobby panel elements
@onready var lobby_status = $LobbyPanel/VBox/LobbyStatus
@onready var create_game_button = $LobbyPanel/VBox/ButtonContainer/CreateGameButton
@onready var join_code_input = $LobbyPanel/VBox/JoinContainer/JoinCodeInput
@onready var join_game_button = $LobbyPanel/VBox/JoinContainer/JoinGameButton
@onready var refresh_lobby_button = $LobbyPanel/VBox/ButtonContainer/RefreshLobbyButton
@onready var games_list = $LobbyPanel/VBox/ScrollContainer/GamesList

# Game room panel elements
@onready var game_code_label = $GameRoomPanel/VBox/GameCodeLabel
@onready var players_list = $GameRoomPanel/VBox/PlayersScrollContainer/PlayersList
@onready var add_ai_button = $GameRoomPanel/VBox/ButtonContainer/AddAIButton
@onready var ready_button = $GameRoomPanel/VBox/ButtonContainer/ReadyButton
@onready var start_game_button = $GameRoomPanel/VBox/ButtonContainer/StartGameButton
@onready var leave_game_button = $GameRoomPanel/VBox/ButtonContainer/LeaveGameButton

var network_manager: NetworkManager
var is_ready: bool = false

func _ready() -> void:
	get_window().title = "Mexican Train - Player Lobby"
		# Use the autoload singleton instead of creating a new instance
	network_manager = NetworkManager
	
	# Connect signals
	network_manager.lobby_updated.connect(_on_lobby_updated)
	network_manager.game_created.connect(_on_game_created)
	network_manager.game_joined.connect(_on_game_joined)
	network_manager.game_started.connect(_on_game_started)
	network_manager.connected_to_server.connect(_on_connected_to_server)
	network_manager.connection_failed.connect(_on_connection_failed)
	
	# Setup button connections
	connect_button.pressed.connect(_on_connect_pressed)
	create_game_button.pressed.connect(_on_create_game_pressed)
	join_game_button.pressed.connect(_on_join_game_pressed)
	refresh_lobby_button.pressed.connect(_on_refresh_lobby_pressed)
	add_ai_button.pressed.connect(_on_add_ai_pressed)
	ready_button.pressed.connect(_on_ready_pressed)
	start_game_button.pressed.connect(_on_start_game_pressed)
	leave_game_button.pressed.connect(_on_leave_game_pressed)
	
	# Start with connection panel
	show_connection_panel()

func show_connection_panel() -> void:
	connection_panel.visible = true
	lobby_panel.visible = false
	game_room_panel.visible = false

func show_lobby_panel() -> void:
	connection_panel.visible = false
	lobby_panel.visible = true
	game_room_panel.visible = false

func show_game_room_panel() -> void:
	connection_panel.visible = false
	lobby_panel.visible = false
	game_room_panel.visible = true

func _on_connect_pressed() -> void:
	Logger.log_debug(Logger.LogArea.LOBBY, "Connect button pressed")
	var input_text = server_address_input.text.strip_edges()
	var address: String
	var port: int
	
	# Parse the input according to the three scenarios:
	# 1) Empty = localhost:9957
	# 2) Address only = address:9957  
	# 3) Address:port = address:port
	
	if input_text.is_empty():
		# Scenario 1: Empty input - use defaults
		address = "127.0.0.1"
		port = NetworkManager.DEFAULT_PORT
		Logger.log_info(Logger.LogArea.LOBBY, "Using default connection: %s:%d" % [address, port])
	elif ":" in input_text:
		# Scenario 3: Address:port specified
		var parts = input_text.split(":", false, 1)  # Split on first colon only
		address = parts[0].strip_edges()
		if address.is_empty():
			address = "127.0.0.1"  # Handle edge case ":9957"
		
		var port_text = parts[1].strip_edges()
		port = port_text.to_int()
		if port <= 0 or port > 65535:
			connection_status.text = "Invalid port number: %s" % port_text
			connection_status.modulate = Color.RED
			Logger.log_warning(Logger.LogArea.LOBBY, "Invalid port: %s" % port_text)
			return
		Logger.log_info(Logger.LogArea.LOBBY, "Using address:port: %s:%d" % [address, port])
	else:
		# Scenario 2: Address only - use default port
		address = input_text
		port = NetworkManager.DEFAULT_PORT
		Logger.log_info(Logger.LogArea.LOBBY, "Using address with default port: %s:%d" % [address, port])
	
	connection_status.text = "Connecting to %s:%d..." % [address, port]
	connection_status.modulate = Color.YELLOW
	Logger.log_info(Logger.LogArea.LOBBY, "Attempting to connect to %s:%d" % [address, port])
	
	var connection_result = network_manager.connect_to_server(address, port)
	Logger.log_debug(Logger.LogArea.LOBBY, "Connection result: %s" % connection_result)
	
	if not connection_result:
		connection_status.text = "Failed to initiate connection"
		connection_status.modulate = Color.RED
		Logger.log_error(Logger.LogArea.LOBBY, "Connection failed to initiate")

func _on_connected_to_server() -> void:
	connection_status.text = "Connected to server!"
	connection_status.modulate = Color.GREEN
	show_lobby_panel()
	network_manager.request_lobby_data()

func _on_connection_failed() -> void:
	connection_status.text = "Failed to connect to server"
	connection_status.modulate = Color.RED

func _on_create_game_pressed() -> void:
	network_manager.create_game()

func _on_join_game_pressed() -> void:
	var game_code = join_code_input.text.strip_edges().to_upper()
	if game_code.length() >= 4:
		network_manager.join_game_with_code(game_code)
	else:
		lobby_status.text = "Please enter a valid game code"
		lobby_status.modulate = Color.ORANGE

func _on_refresh_lobby_pressed() -> void:
	network_manager.request_lobby_data()

func _on_add_ai_pressed() -> void:
	network_manager.add_ai_player()

func _on_ready_pressed() -> void:
	is_ready = not is_ready
	network_manager.set_ready_status(is_ready)
	ready_button.text = "Not Ready" if is_ready else "Ready"
	ready_button.modulate = Color.GREEN if is_ready else Color.WHITE

func _on_start_game_pressed() -> void:
	network_manager.start_current_game()

func _on_leave_game_pressed() -> void:
	network_manager.disconnect_from_server()
	show_connection_panel()
	connection_status.text = "Disconnected from game"
	connection_status.modulate = Color.GRAY

func _on_lobby_updated(lobby_data: Dictionary) -> void:
	lobby_status.text = "Lobby - %d active games" % lobby_data.size()
	lobby_status.modulate = Color.WHITE
	_update_games_list(lobby_data)

func _on_game_created(game_code: String) -> void:
	game_code_label.text = "Game Code: %s (Share this with friends!)" % game_code
	show_game_room_panel()

func _on_game_joined(game_code: String) -> void:
	game_code_label.text = "Game Code: %s" % game_code
	show_game_room_panel()

func _on_game_started(_game_code: String) -> void:
	# Switch to actual game scene
	get_tree().change_scene_to_file("res://scenes/test/mexican_train_multiplayer_test.tscn")

func _update_games_list(lobby_data: Dictionary) -> void:
	# Clear existing games
	for child in games_list.get_children():
		child.queue_free()
	
	if lobby_data.is_empty():
		var no_games_label = Label.new()
		no_games_label.text = "No games available. Create one!"
		no_games_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		games_list.add_child(no_games_label)
		return
	
	# Show available games
	for game_code in lobby_data:
		var game_info = lobby_data[game_code]
		var game_item = _create_game_item(game_code, game_info)
		games_list.add_child(game_item)

func _create_game_item(game_code: String, game_info: Dictionary) -> Control:
	var item_panel = Panel.new()
	item_panel.custom_minimum_size = Vector2(0, 80)
	
	var hbox = HBoxContainer.new()
	item_panel.add_child(hbox)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	
	# Game info
	var info_vbox = VBoxContainer.new()
	hbox.add_child(info_vbox)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var title_label = Label.new()
	title_label.text = "Code: %s (Host: %s)" % [game_code, game_info.get("host_name", "Unknown")]
	info_vbox.add_child(title_label)
	
	var status_label = Label.new()
	var player_count = game_info.get("player_count", 0)
	var max_players = game_info.get("max_players", 8)
	status_label.text = "Players: %d/%d" % [player_count, max_players]
	info_vbox.add_child(status_label)
	
	# Join button
	var join_button = Button.new()
	join_button.text = "Join"
	join_button.custom_minimum_size = Vector2(80, 0)
	join_button.disabled = game_info.get("is_full", false)
	join_button.pressed.connect(_join_specific_game.bind(game_code))
	hbox.add_child(join_button)
	
	return item_panel

func _join_specific_game(game_code: String) -> void:
	network_manager.join_game_with_code(game_code)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				if game_room_panel.visible:
					_on_leave_game_pressed()
				elif lobby_panel.visible:
					show_connection_panel()
				else:
					get_tree().quit()
			KEY_F5:
				if lobby_panel.visible:
					_on_refresh_lobby_pressed()
