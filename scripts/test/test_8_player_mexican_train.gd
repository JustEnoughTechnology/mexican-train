extends Control

## 8-Player Mexican Train Aesthetic Test
## Features improved color palettes and comprehensive multiplayer layout using Player objects

# Scene references
@onready var boneyard = $GameLayout/BoneYard
@onready var central_station = $GameLayout/CentralStation
@onready var mexican_train = $GameLayout/MexicanTrain
@onready var title_label = $UI/TitleLabel
@onready var instructions_label = $UI/InstructionsLabel

# Player management
var players: Array[Player] = []
var current_player_index: int = 0

# Preloaded player scene
var player_scene: PackedScene = preload("res://scenes/players/player.tscn")

# Color themes
var current_theme_index := 0
var color_themes := [
	{
		"name": "Ocean Breeze",
		"background": Color(0.12, 0.16, 0.22, 1),
		"boneyard": Color(0.25, 0.3, 0.4, 0.9),
		"mexican_train": Color(0.15, 0.4, 0.6, 1),
		"players": [
			Color(0.3, 0.6, 0.8, 0.9),   # Player 1 - Sky Blue
			Color(0.6, 0.4, 0.7, 0.9),   # Player 2 - Lavender
			Color(0.5, 0.7, 0.4, 0.9),   # Player 3 - Sage Green
			Color(0.8, 0.6, 0.3, 0.9),   # Player 4 - Warm Gold
			Color(0.7, 0.5, 0.6, 0.9),   # Player 5 - Rose
			Color(0.4, 0.7, 0.7, 0.9),   # Player 6 - Teal
			Color(0.6, 0.3, 0.5, 0.9),   # Player 7 - Plum
			Color(0.8, 0.4, 0.2, 0.9)    # Player 8 - Coral
		]
	},
	{
		"name": "Forest Glade",
		"background": Color(0.08, 0.15, 0.1, 1),
		"boneyard": Color(0.2, 0.3, 0.2, 0.9),
		"mexican_train": Color(0.6, 0.3, 0.1, 1),
		"players": [
			Color(0.4, 0.7, 0.3, 0.9),   # Player 1 - Forest Green
			Color(0.6, 0.7, 0.4, 0.9),   # Player 2 - Olive
			Color(0.3, 0.5, 0.4, 0.9),   # Player 3 - Pine
			Color(0.7, 0.5, 0.3, 0.9),   # Player 4 - Amber
			Color(0.5, 0.6, 0.7, 0.9),   # Player 5 - Storm Blue
			Color(0.7, 0.4, 0.5, 0.9),   # Player 6 - Berry
			Color(0.4, 0.4, 0.6, 0.9),   # Player 7 - Twilight
			Color(0.8, 0.6, 0.4, 0.9)    # Player 8 - Sunset
		]
	},
	{
		"name": "Sunset Mesa",
		"background": Color(0.18, 0.12, 0.15, 1),
		"boneyard": Color(0.4, 0.3, 0.25, 0.9),
		"mexican_train": Color(0.8, 0.3, 0.2, 1),
		"players": [
			Color(0.9, 0.5, 0.3, 0.9),   # Player 1 - Sunset Orange
			Color(0.7, 0.4, 0.5, 0.9),   # Player 2 - Desert Rose
			Color(0.6, 0.5, 0.7, 0.9),   # Player 3 - Sage Purple
			Color(0.8, 0.7, 0.4, 0.9),   # Player 4 - Golden Sand
			Color(0.5, 0.6, 0.5, 0.9),   # Player 5 - Cactus Green
			Color(0.7, 0.6, 0.6, 0.9),   # Player 6 - Clay Pink
			Color(0.4, 0.5, 0.6, 0.9),   # Player 7 - Storm Gray
			Color(0.6, 0.3, 0.4, 0.9)    # Player 8 - Mesa Red
		]
	},
	{
		"name": "Arctic Dawn",
		"background": Color(0.15, 0.18, 0.22, 1),
		"boneyard": Color(0.3, 0.35, 0.4, 0.9),
		"mexican_train": Color(0.2, 0.5, 0.7, 1),
		"players": [
			Color(0.7, 0.8, 0.9, 0.9),   # Player 1 - Ice Blue
			Color(0.6, 0.7, 0.8, 0.9),   # Player 2 - Frost
			Color(0.5, 0.7, 0.7, 0.9),   # Player 3 - Glacier
			Color(0.8, 0.8, 0.7, 0.9),   # Player 4 - Snow
			Color(0.7, 0.6, 0.8, 0.9),   # Player 5 - Aurora Purple
			Color(0.6, 0.8, 0.7, 0.9),   # Player 6 - Mint Ice
			Color(0.5, 0.6, 0.7, 0.9),   # Player 7 - Steel Blue
			Color(0.8, 0.7, 0.6, 0.9)    # Player 8 - Warm White
		]
	}
]

func _ready() -> void:
	get_window().title = "8-Player Mexican Train - Aesthetic Test"
	get_window().mode = Window.MODE_MAXIMIZED
	
	# Ensure we use the full screen size
	await get_tree().process_frame  # Wait for window to be properly sized
	setup_layout_containers()
		# Initialize game components
	setup_game()
	position_center_components()
	
	# Collect player components
	await collect_player_components()
	
	# Apply initial theme
	apply_color_theme(0)
	
	# Show instructions
	update_instructions()
	
	print("=== 8-Player Mexican Train Aesthetic Test ===")
	print("• 8 players with unique color schemes")
	print("• Multiple aesthetic themes available")
	print("• Press C to cycle through color themes")
	print("• Press Spacebar to toggle debug overlays")

func setup_game() -> void:
	# Populate boneyard with all dominoes
	if boneyard and boneyard.has_method("populate"):
		boneyard.populate(6, false)  # Face down initially
		print("BoneYard populated with 28 dominoes")
	
	# Initialize central station
	if central_station and central_station.has_method("initialize_empty"):
		central_station.initialize_empty()
		print("Central Station initialized")
	
	# Initialize Mexican train
	if mexican_train and mexican_train.has_method("clear_train"):
		mexican_train.clear_train()
		print("Mexican Train initialized")

func collect_player_components() -> void:
	"""Create 8 Player objects with unique names and colors"""
	# Clear any previously used names to start fresh
	var player_name_util = preload("res://scripts/util/player_name_util.gd")
	player_name_util.clear_used_names()
	
	print("Creating 8 players with unique names...")
	
	# Create all players first, then initialize them
	for i in range(1, 9):  # Players 1-8
		# Create player instance
		var player = player_scene.instantiate()
		add_child(player)
		players.append(player)
		
		print("Created player %d container" % i)
	
	# Now initialize all players with proper timing
	for i in range(players.size()):
		var player = players[i]
		var player_number = i + 1
		
		# Get color from current theme
		var player_color = get_player_color_for_theme(i, current_theme_index)
		
		# Initialize player with unique name and color (await for proper timing)
		await player.initialize_player(player_number, "", player_color, true)
		
		# Position player components in the scene
		position_player_components(player, player_number)
		
		print("Initialized Player %d: %s (Color: %s)" % [player_number, player.get_player_name(), player_color])
	
	print("Successfully created and positioned %d players" % players.size())

func position_player_components(player: Player, player_number: int) -> void:
	"""Position the player's hand and train components in organized layout areas"""
	var hand = player.get_hand()
	var train = player.get_train()
	
	if not hand or not train:
		print("Warning: Player %d missing hand or train component" % player_number)
		return
	
	var screen_size = get_viewport().get_visible_rect().size
		# Calculate positions for organized layout
	# Left 30% for hands, Center 40% for game board, Right 30% for trains
	var hands_area_width = screen_size.x * 0.3
	var trains_area_start = screen_size.x * 0.7
	var trains_area_width = screen_size.x * 0.3
		# Calculate vertical positions (8 players, stack them vertically)
	var available_height = screen_size.y - 120  # Leave space for titles and instructions
	var slot_height = available_height / 8.0
	var y_position = 80 + (player_number - 1) * slot_height  # Start after title space
	
	# Make components smaller and more manageable
	var component_height = min(slot_height - 5, 70)  # Max 70px high, with 5px spacing
	
	# Position hand in left area
	hand.position = Vector2(10, y_position)
	hand.custom_minimum_size = Vector2(hands_area_width - 20, component_height)
	hand.size = hand.custom_minimum_size
	
	# Position train in right area  
	train.position = Vector2(trains_area_start + 10, y_position)	
	train.custom_minimum_size = Vector2(trains_area_width - 20, component_height)
	train.size = train.custom_minimum_size
	
	print("Positioned Player %d: Hand at (%d, %d), Train at (%d, %d), Size: %s" % [
		player_number, hand.position.x, hand.position.y, train.position.x, train.position.y, hand.size
	])
	
	# Debug: Make sure components are visible
	hand.visible = true
	train.visible = true
	hand.modulate = Color.WHITE
	train.modulate = Color.WHITE

func position_center_components() -> void:
	"""Position the center game components (boneyard, station, mexican train) in the center area"""
	var screen_size = get_viewport().get_visible_rect().size
	var center_start = screen_size.x * 0.3
	var center_width = screen_size.x * 0.4
	var center_x = center_start + center_width / 2
		# Position boneyard in upper center - smaller size
	if boneyard:
		boneyard.position = Vector2(center_x - 80, 80)
		boneyard.custom_minimum_size = Vector2(160, 80)
		print("Positioned boneyard at center-top")
	
	# Position central station in middle center - smaller size
	if central_station:
		central_station.position = Vector2(center_x - 60, 180)
		central_station.custom_minimum_size = Vector2(120, 120)
		print("Positioned central station at center-middle")
	
	# Position Mexican train in lower center - smaller size
	if mexican_train:
		mexican_train.position = Vector2(center_x - 80, 320)
		mexican_train.custom_minimum_size = Vector2(160, 60)
		print("Positioned Mexican train at center-bottom")

func get_player_color_for_theme(player_index: int, theme_index: int) -> Color:
	"""Get the color for a player based on the current theme"""
	if theme_index >= 0 and theme_index < color_themes.size():
		var color_theme = color_themes[theme_index]
		if player_index >= 0 and player_index < color_theme.players.size():
			return color_theme.players[player_index]
	
	# Fallback to default colors
	var default_colors = [
		Color.CYAN, Color.MAGENTA, Color.GREEN, Color.YELLOW,
		Color.ORANGE, Color.PURPLE, Color.PINK, Color.LIME_GREEN
	]
	return default_colors[player_index % default_colors.size()]

func get_player_by_number(player_number: int) -> Player:
	"""Get a player by their player number"""
	for player in players:
		if player.get_player_number() == player_number:
			return player
	return null

func set_active_player(player_number: int) -> void:
	"""Set the active player for turn management"""
	# Deactivate all players
	for player in players:
		player.set_active_turn(false)
	
	# Activate the specified player
	var active_player = get_player_by_number(player_number)
	if active_player:
		active_player.set_active_turn(true)
		current_player_index = player_number - 1
		print("Player %s is now active" % active_player.get_player_name())

func apply_color_theme(theme_index: int) -> void:
	if theme_index < 0 or theme_index >= color_themes.size():
		return
	
	var selected_theme = color_themes[theme_index]
	print("Applying theme: %s" % selected_theme.name)
	
	# Apply background color
	var background = $Background
	if background:
		background.color = selected_theme.background
	
	# Apply boneyard color
	if boneyard:
		boneyard.bg_color = selected_theme.boneyard
	
	# Apply Mexican train color
	if mexican_train:
		mexican_train.color = selected_theme.mexican_train
	
	# Apply player colors using Player objects
	for i in range(min(players.size(), selected_theme.players.size())):
		var player = players[i]
		var player_color = selected_theme.players[i]
		
		# Update the player's color
		player.player_color = player_color
		
		# Apply to hand
		var hand = player.get_hand()
		if hand:
			hand.bg_color = player_color
		
		# Apply to train with slightly more transparency
		var train = player.get_train()
		if train:
			var train_color = player_color
			train_color.a = 0.8  # Slightly more transparent for trains
			train.color = train_color
		# Update title to show current theme
	if title_label:
		title_label.text = "8-Player Mexican Train - %s Theme" % selected_theme.name

func update_instructions() -> void:
	var instructions = """LAYOUT: 
• LEFT SIDE: All 8 player hands grouped together
• RIGHT SIDE: All 8 player trains grouped together  
• CENTER: Boneyard, Station, and Mexican Train

CONTROLS:
• Spacebar: Toggle debug overlays
• Enter: Toggle debug warnings  
• C: Cycle color themes (%d/%d)
• Drag dominoes from boneyard to hands
• Place engine domino in central station

FEATURES: 
• Full-screen maximized layout
• Unique player names with PlayerNameUtil system
• 8-player color schemes that change with themes
• Organized layout for easy gameplay""" % [current_theme_index + 1, color_themes.size()]
	
	if instructions_label:
		instructions_label.text = instructions

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var keycode = event.keycode
		
		# Cycle color themes with C key
		if keycode == KEY_C:
			current_theme_index = (current_theme_index + 1) % color_themes.size()
			apply_color_theme(current_theme_index)
			update_instructions()
			print("Switched to theme: %s" % color_themes[current_theme_index].name)
		
		# Toggle debug warnings with Enter
		elif keycode == KEY_ENTER or keycode == KEY_KP_ENTER:
			GameConfig.DEBUG_SHOW_WARNINGS = not GameConfig.DEBUG_SHOW_WARNINGS
			print("Debug warnings: %s" % ("ON" if GameConfig.DEBUG_SHOW_WARNINGS else "OFF"))
		
		# Toggle orientation overlays with Spacebar
		elif keycode == KEY_SPACE:
			toggle_all_orientation_overlays()
			print("Toggled orientation overlays for all dominoes")

func toggle_all_orientation_overlays() -> void:
	# Toggle overlays for boneyard
	toggle_orientation_overlays_in_container(boneyard, "boneyard_layout/domino_container")
	
	# Toggle overlays for all player hands and trains using Player objects
	for player in players:
		var hand = player.get_hand()
		var train = player.get_train()
		
		if hand:
			toggle_orientation_overlays_in_container(hand, "hand_layout/domino_container")
		if train:
			toggle_orientation_overlays_in_container(train, "TopContainer/bg/DominoContainer")
	
	# Toggle overlays for Mexican train
	toggle_orientation_overlays_in_container(mexican_train, "TopContainer/bg/DominoContainer")
	
	# Toggle overlays for central station
	if central_station and central_station.has_node("DominoContainer"):
		var station_container = central_station.get_node("DominoContainer")
		for domino in station_container.get_children():
			if domino.has_method("toggle_orientation_label"):
				domino.toggle_orientation_label()

func toggle_orientation_overlays_in_container(parent_node: Node, container_path: String) -> void:
	if not parent_node or not parent_node.has_node(container_path):
		return
	
	var container = parent_node.get_node(container_path)
	for domino in container.get_children():
		if domino.has_method("toggle_orientation_label"):
			domino.toggle_orientation_label()

# Utility functions for game statistics
func get_game_stats() -> Dictionary:
	var stats = {}
	stats["theme"] = color_themes[current_theme_index].name
	stats["boneyard_count"] = boneyard.get_node("boneyard_layout/domino_container").get_child_count() if boneyard else 0
	stats["mexican_train_count"] = mexican_train.get_domino_count() if mexican_train and mexican_train.has_method("get_domino_count") else 0
	
	# Count dominoes for each player using Player objects
	for i in range(players.size()):
		var player = players[i]
		var hand = player.get_hand()
		var train = player.get_train()
		
		var hand_count = hand.get_domino_count() if hand and hand.has_method("get_domino_count") else 0
		var train_count = train.get_domino_count() if train and train.has_method("get_domino_count") else 0
		
		stats["player_%d_hand" % (i + 1)] = hand_count
		stats["player_%d_train" % (i + 1)] = train_count
		stats["player_%d_name" % (i + 1)] = player.get_player_name()
	
	return stats

func print_game_stats() -> void:
	var stats = get_game_stats()
	print("=== GAME STATS - %s Theme ===" % stats.theme)
	print("Boneyard: %d dominoes" % stats.boneyard_count)
	print("Mexican Train: %d dominoes" % stats.mexican_train_count)
	
	for i in range(players.size()):
		var hand_key = "player_%d_hand" % (i + 1)
		var train_key = "player_%d_train" % (i + 1)
		var name_key = "player_%d_name" % (i + 1)
		print("Player %d (%s): Hand(%d) Train(%d)" % [i + 1, stats.get(name_key, "Unknown"), stats.get(hand_key, 0), stats.get(train_key, 0)])
	print("=======================")

func print_player_names() -> void:
	"""Debug function to print all player names"""
	print("=== PLAYER NAMES ===")
	for i in range(players.size()):
		var player = players[i]
		print("Player %d: %s (Color: %s)" % [i + 1, player.get_player_name(), player.get_player_color()])
	print("=====================")

# Color theme information for debugging
func print_color_themes() -> void:
	print("=== AVAILABLE COLOR THEMES ===")
	for i in range(color_themes.size()):
		var color_theme = color_themes[i]
		var current = " (CURRENT)" if i == current_theme_index else ""
		print("%d. %s%s" % [i + 1, color_theme.name, current])
	print("===============================")

func setup_layout_containers() -> void:
	"""Create organized layout areas for hands and trains"""
	var screen_size = get_viewport().get_visible_rect().size
	
	# Create visual labels for layout areas
	create_area_label("PLAYER HANDS", Vector2(screen_size.x * 0.15, 20), Color.CYAN)
	create_area_label("GAME BOARD", Vector2(screen_size.x * 0.5, 20), Color.YELLOW)  
	create_area_label("PLAYER TRAINS", Vector2(screen_size.x * 0.85, 20), Color.MAGENTA)
	
	print("Setting up organized layout areas:")
	print("- Left 30%: Player Hands")
	print("- Center 40%: Game Board (Boneyard, Station, Mexican Train)")
	print("- Right 30%: Player Trains")
	print("- Screen size: %s" % screen_size)

func create_area_label(text: String, pos: Vector2, color: Color) -> void:
	"""Create a label to identify layout areas"""
	var label = Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(200, 30)
	add_child(label)
