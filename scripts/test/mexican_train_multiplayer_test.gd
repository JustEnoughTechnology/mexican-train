extends Control

## Multiplayer Mexican Train Game
## Single-window layout showing all players around central station
## Network-friendly approach replacing floating windows

# Scene references
@onready var boneyard = $GameLayout/BoneYard
@onready var central_station = $GameLayout/CenterArea/Station
@onready var mexican_train = $GameLayout/CenterArea/MexicanTrain
@onready var connection_panel = $UI/ConnectionPanel
@onready var game_panel = $UI/GamePanel
@onready var status_label = $UI/GamePanel/StatusLabel
@onready var turn_indicator = $UI/GamePanel/TurnIndicator

# Player layout containers (8 positions around station)
@onready var player_areas = {
	1: $GameLayout/PlayerAreas/TopLeft,      # Player 1
	2: $GameLayout/PlayerAreas/TopCenter,   # Player 2  
	3: $GameLayout/PlayerAreas/TopRight,    # Player 3
	4: $GameLayout/PlayerAreas/RightCenter, # Player 4
	5: $GameLayout/PlayerAreas/BottomRight, # Player 5
	6: $GameLayout/PlayerAreas/BottomCenter,# Player 6
	7: $GameLayout/PlayerAreas/BottomLeft,  # Player 7
	8: $GameLayout/PlayerAreas/LeftCenter   # Player 8
}

# Game state
var game_started: bool = false
var engine_placed: bool = false
var local_player: Player = null
var active_players: Dictionary = {}

# Network references
@onready var network_manager = NetworkManager

func _ready() -> void:
	get_window().title = "Mexican Train - Multiplayer"
	get_window().mode = Window.MODE_MAXIMIZED
	
	# Connect network signals
	network_manager.player_connected.connect(_on_player_connected)
	network_manager.player_disconnected.connect(_on_player_disconnected)
	network_manager.game_state_updated.connect(_on_game_state_updated)
	
	# Connect EventBus signals for networked events
	EventBus.turn_changed.connect(_on_turn_changed)
	EventBus.network_domino_action.connect(_on_network_domino_action)
	EventBus.player_list_updated.connect(_on_player_list_updated)
	
	# Setup initial UI
	show_connection_screen()
	setup_game_layout()

func show_connection_screen() -> void:
	"""Show the initial connection/lobby screen"""
	connection_panel.visible = true
	game_panel.visible = false
	
	# Setup connection panel buttons
	var host_button = connection_panel.get_node("VBox/HostButton")
	var join_button = connection_panel.get_node("VBox/JoinButton") 
	var address_input = connection_panel.get_node("VBox/AddressInput")
	
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed.bind(address_input))

func show_game_screen() -> void:
	"""Show the main game screen"""
	connection_panel.visible = false
	game_panel.visible = true
	
	# Initialize game components
	setup_game()

func setup_game_layout() -> void:
	"""Setup the circular player layout around central station"""
	# Position player areas in a circle around the station
	var center = Vector2(960, 540)  # Assuming 1920x1080 screen
	var radius = 300
	
	for i in range(8):
		var angle = i * PI / 4  # 8 positions around circle
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		
		if i + 1 in player_areas:
			var area = player_areas[i + 1]
			area.position = pos - area.size / 2

func setup_game() -> void:
	"""Initialize game components for multiplayer"""
	# Populate boneyard (host only)
	if network_manager.is_host and boneyard.has_method("populate"):
		boneyard.populate(6, false)  # Face down initially
		print("BoneYard populated with 28 dominoes")
	
	# Initialize station
	if central_station.has_method("initialize_empty"):
		central_station.initialize_empty()
		print("Central station ready for engine domino")
	
	# Connect station signals
	if central_station.has_signal("engine_domino_placed"):
		central_station.engine_domino_placed.connect(_on_engine_placed)
	
	update_status("Game ready! Waiting for all players...")

func create_local_player(player_id: int, player_name: String) -> void:
	"""Create the local player's hand and train"""
	# Create player instance
	local_player = Player.new()
	local_player.initialize_player(player_id, player_name, Color.CYAN, true)
	
	# Get assigned area for this player
	var player_area = get_player_area(player_id)
	if player_area:
		# Create hand in player area
		var hand = local_player.get_hand()
		var train = local_player.get_train()
		
		if hand and train:
			player_area.add_child(hand)
			player_area.add_child(train)
			
			# Position hand and train within the area
			hand.position = Vector2(0, 0)
			train.position = Vector2(0, 100)
			
			# Enable drag-drop for local player only
			hand.enable_drop_target()
			train.enable_drop_target()
			
			print("Local player %s created in area %d" % [player_name, player_id])

func create_remote_player_display(player_id: int, player_name: String) -> void:
	"""Create display for remote player (view-only)"""
	var player_area = get_player_area(player_id)
	if not player_area:
		return
	
	# Create display-only hand and train
	var hand_scene = preload("res://scenes/hand/hand.tscn")
	var train_scene = preload("res://scenes/train/train.tscn")
	
	var hand = hand_scene.instantiate()
	var train = train_scene.instantiate()
	
	# Configure for remote display
	hand.name = "RemoteHand_%d" % player_id
	train.name = "RemoteTrain_%d" % player_id
	hand.set_label_text("%s's Hand" % player_name)
	train.set_label_text("%s's Train" % player_name)
	
	# Disable interaction for remote players
	hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	train.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Add to player area
	player_area.add_child(hand)
	player_area.add_child(train)
	
	# Position within area
	hand.position = Vector2(0, 0)
	train.position = Vector2(0, 100)
	
	# Store reference
	active_players[player_id] = {
		"hand": hand,
		"train": train,
		"name": player_name
	}
	
	print("Remote player display created for %s (ID: %d)" % [player_name, player_id])

func get_player_area(player_id: int) -> Control:
	"""Get the area assigned to a player ID"""
	if player_id in player_areas:
		return player_areas[player_id]
	
	# If more than 8 players, need to handle overflow
	var overflow_id = ((player_id - 1) % 8) + 1
	return player_areas.get(overflow_id)

func update_status(message: String) -> void:
	"""Update the status display"""
	if status_label:
		status_label.text = message
	print("[MULTIPLAYER] %s" % message)

func update_turn_indicator(active_player_id: int) -> void:
	"""Update the turn indicator"""
	var player_data = network_manager.players.get(active_player_id, {})
	var player_name = player_data.get("name", "Unknown")
	
	if turn_indicator:
		if active_player_id == network_manager.local_player_id:
			turn_indicator.text = "YOUR TURN"
			turn_indicator.modulate = Color.GREEN
		else:
			turn_indicator.text = "%s's Turn" % player_name
			turn_indicator.modulate = Color.YELLOW

# Network event handlers
func _on_player_connected(peer_id: int, player_name: String) -> void:
	"""Handle new player joining"""
	update_status("Player joined: %s" % player_name)
	
	if peer_id == network_manager.local_player_id:
		# This is us joining
		create_local_player(peer_id, player_name)
	else:
		# Remote player joining
		create_remote_player_display(peer_id, player_name)

func _on_player_disconnected(peer_id: int) -> void:
	"""Handle player leaving"""
	if peer_id in active_players:
		var player_data = active_players[peer_id]
		update_status("Player left: %s" % player_data.name)
		
		# Remove their display
		if player_data.hand:
			player_data.hand.queue_free()
		if player_data.train:
			player_data.train.queue_free()
		
		active_players.erase(peer_id)

func _on_game_state_updated(_state: Dictionary) -> void:
	"""Handle game state updates from host"""
	# Update game components based on received state
	pass

func _on_turn_changed(active_player_id: int) -> void:
	"""Handle turn changes"""
	update_turn_indicator(active_player_id)

func _on_network_domino_action(action: String, _data: Dictionary) -> void:
	"""Handle networked domino actions"""
	match action:
		"domino_placed":
			# Update display for domino placement
			pass
		"domino_drawn":
			# Update display for domino drawing
			pass

func _on_player_list_updated(players: Dictionary) -> void:
	"""Handle updated player list"""
	# Update displays for all players
	for player_id in players:
		var player_data = players[player_id]
		if player_id not in active_players and player_id != network_manager.local_player_id:
			create_remote_player_display(player_id, player_data.name)

func _on_engine_placed() -> void:
	"""Handle engine domino placement"""
	engine_placed = true
	game_started = true
	update_status("Engine placed! Game started!")
	
	# Sync to all players if host
	if network_manager.is_host:
		network_manager.sync_game_state({"engine_placed": true, "game_started": true})

# Connection button handlers
func _on_host_pressed() -> void:
	"""Handle host game button"""
	if network_manager.host_game():
		update_status("Hosting game on port %d" % NetworkManager.DEFAULT_PORT)
		show_game_screen()
	else:
		update_status("Failed to host game")

func _on_join_pressed(address_input: LineEdit) -> void:
	"""Handle join game button"""
	var address = address_input.text.strip_edges()
	if address.is_empty():
		address = "127.0.0.1"  # Default to localhost
	
	if network_manager.join_game(address):
		update_status("Connecting to %s..." % address)
		# Wait for connection result
		await network_manager.connected_to_server
		show_game_screen()
	else:
		update_status("Failed to connect to %s" % address)

func _input(event: InputEvent) -> void:
	"""Handle global input events"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				# Disconnect and return to connection screen
				if network_manager.is_connected:
					network_manager.disconnect_from_game()
					show_connection_screen()
					update_status("Disconnected from game")
			KEY_ENTER:
				# Toggle debug warnings
				GameConfig.DEBUG_SHOW_WARNINGS = not GameConfig.DEBUG_SHOW_WARNINGS
				update_status("Debug warnings: %s" % ("ON" if GameConfig.DEBUG_SHOW_WARNINGS else "OFF"))
