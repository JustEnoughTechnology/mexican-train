extends Control

## 8-Player Mexican Train Clean Layout Test
## Features floating hand windows and trains distributed around the central station

# Scene references
@onready var boneyard = $GameBoard/BoneYard
@onready var central_station = $GameBoard/CentralStation
@onready var mexican_train = $GameBoard/MexicanTrain
@onready var title_label = $UI/TitleLabel
@onready var instructions_label = $UI/InstructionsLabel

# Floating hand windows
var floating_hand_scene = preload("res://scenes/hand/floating_hand_window.tscn")
var floating_hands: Array[Window] = []

# Train references (now distributed around station)
@onready var player_trains = [
	$PlayerTrains/Player1Train,  # Top Left
	$PlayerTrains/Player2Train,  # Top Center  
	$PlayerTrains/Player3Train,  # Top Right
	$PlayerTrains/Player4Train,  # Right Center
	$PlayerTrains/Player5Train,  # Bottom Right
	$PlayerTrains/Player6Train,  # Bottom Center
	$PlayerTrains/Player7Train,  # Bottom Left
	$PlayerTrains/Player8Train   # Left Center
]

# Color management
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
			Color(0.6, 0.6, 0.4, 0.9)    # Player 8 - Sage
		]
	},
	{
		"name": "Sunset Valley",
		"background": Color(0.15, 0.1, 0.08, 1),
		"boneyard": Color(0.3, 0.25, 0.2, 0.9),
		"mexican_train": Color(0.6, 0.4, 0.2, 1),
		"players": [
			Color(0.8, 0.5, 0.3, 0.9),   # Player 1 - Sunset Orange
			Color(0.7, 0.3, 0.4, 0.9),   # Player 2 - Deep Rose
			Color(0.5, 0.4, 0.7, 0.9),   # Player 3 - Evening Purple
			Color(0.6, 0.6, 0.3, 0.9),   # Player 4 - Golden Hour
			Color(0.4, 0.6, 0.5, 0.9),   # Player 5 - Dusk Teal
			Color(0.7, 0.6, 0.5, 0.9),   # Player 6 - Warm Sand
			Color(0.5, 0.3, 0.6, 0.9),   # Player 7 - Twilight Plum
			Color(0.6, 0.4, 0.4, 0.9)    # Player 8 - Dusky Pink
		]
	}
]

# Player name utility
var player_names := []

func _ready():
	# Set initial window mode to maximized
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	await get_tree().process_frame
	
	# Generate player names using OS username + digit
	generate_player_names()
	
	# Apply initial theme
	apply_current_theme()
	
	# Set up player components
	setup_player_components()
	
	# Populate the boneyard with dominoes
	populate_boneyard()
	
	# Initialize central station with starting domino for visibility
	if central_station and central_station.has_method("initialize_with_double"):
		central_station.initialize_with_double(6)  # Start with 6-6 domino
		print("Central station initialized with 6-6 starting domino")
		print("8-Player Mexican Train Clean Layout Test initialized")
	print("Controls: C = Cycle themes, H = Toggle hand windows, S = Toggle single domino mode, D = Debug layout info, ESC = Quit")
	print("Station should be visible between boneyard and Mexican train")
	
	# Add a small delay to ensure all elements are fully loaded, then print debug info
	await get_tree().process_frame
	await get_tree().process_frame
	print_layout_debug_info()

func create_floating_hand_windows():
	"""Create floating windows for all player hands"""
	var window_size = get_viewport().get_visible_rect().size
	var window_positions = calculate_hand_window_positions(window_size)
	
	for i in range(8):
		var floating_window = floating_hand_scene.instantiate()
		floating_hands.append(floating_window)
		
		# Set up the floating window
		var player_name = player_names[i]
		var player_number = i + 1
		floating_window.setup_hand(player_name, player_number, self)
		
		# Set window position
		floating_window.set_window_position(window_positions[i])
		
		# Connect signals
		floating_window.hand_closed.connect(_on_hand_window_closed)
		floating_window.domino_drag_started.connect(_on_hand_drag_started)
		floating_window.domino_dropped_to_main.connect(_on_domino_dropped_to_main)
		
		# Apply color theme
		var hand_color = color_themes[current_theme_index].players[i]
		hand_color.a = 0.8
		hand_color = hand_color.darkened(0.1)
		floating_window.set_hand_color(hand_color)
		
		# Add to scene tree
		add_child(floating_window)
		
		print("Created floating window for %s at position %s" % [player_name, window_positions[i]])

func calculate_hand_window_positions(screen_size: Vector2) -> Array[Vector2i]:
	"""Calculate optimal positions for floating hand windows"""
	var positions: Array[Vector2i] = []
	var window_width = 400
	var window_height = 150
	var margin = 20
	
	# Distribute windows around the edges of the screen
	# Top edge (players 1-3)
	for i in range(3):
		var x = margin + i * (window_width + margin)
		positions.append(Vector2i(x, margin))
	
	# Right edge (players 4-5)
	for i in range(2):
		var x = int(screen_size.x) - window_width - margin
		var y = margin + 200 + i * (window_height + margin)
		positions.append(Vector2i(x, y))
	
	# Bottom edge (players 6-8)
	for i in range(3):
		var x = margin + i * (window_width + margin)
		var y = int(screen_size.y) - window_height - margin - 50  # Account for taskbar
		positions.append(Vector2i(x, y))
	
	return positions

func _on_hand_drag_started(_domino, from_window: Window):
	"""Handle when a domino drag starts from a floating hand window"""
	print("Domino drag started from floating window: %s" % from_window.title)

func _on_domino_dropped_to_main(_domino, drop_position: Vector2):
	"""Handle when a domino is dropped from a floating window to the main scene"""
	print("Domino dropped to main scene at position: %s" % drop_position)

func handle_cross_window_drag(_domino, from_window: Window):
	"""Handle dragging between floating windows and main scene"""
	print("Cross-window drag started from window: %s" % from_window.title)
	# Could implement drag preview in main window here

func _on_hand_window_closed(player_number: int):
	"""Handle when a hand window is closed"""
	print("Hand window %d was closed" % player_number)
	# Could minimize instead of closing
	if player_number <= floating_hands.size():
		var window = floating_hands[player_number - 1]
		if window:
			window.minimize_window()

func generate_player_names():
	"""Generate player names using OS username + single digit (1-8)"""
	var player_name_util = preload("res://scripts/util/player_name_util.gd")
	var base_name = player_name_util.get_os_username()
	
	if base_name == "":
		base_name = "Player"
	
	player_names.clear()
	for i in range(8):
		var player_name = "%s%d" % [base_name, i + 1]
		player_names.append(player_name)
	
	print("Generated player names: %s" % str(player_names))

func setup_player_components():
	"""Set up all player trains and create floating hand windows"""
	
	# Set up Mexican Train label
	if mexican_train and mexican_train.has_method("set_label_text"):
		mexican_train.set_label_text("Mexican Train")
		# Enable single domino mode for Mexican Train
		if mexican_train.has_method("set_single_domino_mode"):
			mexican_train.set_single_domino_mode(true)
	
	# Set up Central Station for visibility
	if central_station:
		# Ensure the station is visible and properly sized
		central_station.custom_minimum_size = Vector2(150, 60)
		if central_station.has_method("set_background_color"):
			central_station.set_background_color(Color(0.9, 0.9, 0.8, 1))
		else:
			central_station.color = Color(0.9, 0.9, 0.8, 1)
		print("Central station set up for visibility")
	
	# Create floating hand windows
	create_floating_hand_windows()
	
	# Set up trains (now distributed around station)
	for i in range(8):
		var player_number = i + 1
		var player_name = player_names[i]
		
		# Set up train
		if player_trains[i]:
			if player_trains[i].has_method("set_label_text"):
				player_trains[i].set_label_text("%s (P%d)" % [player_name, player_number])
			
			# Make trains more compact for the distributed layout
			player_trains[i].custom_minimum_size = Vector2(160, 40)
			
			# Enable single domino mode for space efficiency
			if player_trains[i].has_method("set_single_domino_mode"):
				player_trains[i].set_single_domino_mode(true)
			
			# Force a stronger background color for better visibility
			var train_color = color_themes[current_theme_index].players[i]
			train_color.a = 1.0  # Make fully opaque
			# Brighten the color for better visibility
			train_color = train_color.lightened(0.2)
			
			# Try multiple methods to set the color
			if player_trains[i].has_method("set_background_color"):
				player_trains[i].set_background_color(train_color)
			# Also set via bg_color property
			player_trains[i].bg_color = train_color
			# Set the root ColorRect color too
			player_trains[i].color = train_color
			
			print("Set up train %d: %s with color %s" % [i+1, player_name, train_color])

func populate_boneyard():
	"""Populate the boneyard with a standard double-6 domino set"""
	if not boneyard or not boneyard.has_method("populate"):
		print("Warning: Boneyard not found or missing populate method")
		return
	
	# Populate with double-6 set (0-0 through 6-6, total of 28 dominoes)
	boneyard.populate(6, false)  # 6 = max dots, false = face down initially
	print("Boneyard populated with double-6 domino set (28 dominoes)")

func apply_current_theme():
	"""Apply the current color theme to all components"""
	var color_theme = color_themes[current_theme_index]
	
	# Update title
	if title_label:
		title_label.text = "8-Player Mexican Train - %s Theme" % color_theme.name
	
	# Apply background color
	var background = $Background
	if background:
		background.color = color_theme.background
		# Apply boneyard color
	if boneyard and boneyard.has_method("set_background_color"):
		boneyard.set_background_color(color_theme.boneyard)
	
	# Apply central station color
	if central_station and central_station.has_method("set_background_color"):
		central_station.set_background_color(Color(0.9, 0.9, 0.8, 1))  # Light cream color for visibility
	elif central_station:
		central_station.color = Color(0.9, 0.9, 0.8, 1)
	
	# Apply Mexican train color
	if mexican_train and mexican_train.has_method("set_background_color"):
		mexican_train.set_background_color(color_theme.mexican_train)
	# Apply player colors to floating hands and trains
	for i in range(min(8, color_theme.players.size())):
		var player_color = color_theme.players[i]
		
		# Apply to floating hand windows
		if i < floating_hands.size() and floating_hands[i]:
			var hand_color = player_color.darkened(0.1)
			hand_color.a = 0.8  # Slightly more transparent than trains
			floating_hands[i].set_hand_color(hand_color)
		
		# Apply to train with enhanced visibility
		if player_trains[i] and player_trains[i].has_method("set_background_color"):
			var enhanced_train_color = player_color
			enhanced_train_color.a = 1.0  # Make trains fully opaque
			# Brighten the color significantly for better visibility
			enhanced_train_color = enhanced_train_color.lightened(0.3)
			
			# Apply color via multiple methods to ensure it works
			player_trains[i].set_background_color(enhanced_train_color)
			player_trains[i].bg_color = enhanced_train_color
			player_trains[i].color = enhanced_train_color
			
			print("Applied enhanced color to train %d: %s" % [i+1, enhanced_train_color])
	
	print("Applied theme: %s" % color_theme.name)

func cycle_theme():
	"""Cycle to the next color theme"""
	current_theme_index = (current_theme_index + 1) % color_themes.size()
	apply_current_theme()
	# Force a refresh of train colors since they seem stubborn
	refresh_train_colors()

func refresh_train_colors():
	"""Force refresh of train colors for better visibility"""
	var color_theme = color_themes[current_theme_index]
	for i in range(min(8, color_theme.players.size())):
		# Refresh train colors
		if player_trains[i]:
			var train_color = color_theme.players[i]
			train_color.a = 1.0
			train_color = train_color.lightened(0.3)
			
			# Force color through all possible channels
			player_trains[i].bg_color = train_color
			player_trains[i].color = train_color
			if player_trains[i].has_method("set_background_color"):
				player_trains[i].set_background_color(train_color)
			
			# Also try setting the background node directly
			if player_trains[i].has_node("TopContainer/bg"):
				player_trains[i].get_node("TopContainer/bg").color = train_color
			
			print("Force refreshed train %d color: %s" % [i+1, train_color])
		
		# Refresh floating hand window colors to match
		if i < floating_hands.size() and floating_hands[i]:
			var hand_color = color_theme.players[i].darkened(0.1)
			hand_color.a = 0.8
			
			floating_hands[i].set_hand_color(hand_color)
			
			print("Force refreshed floating hand %d color: %s" % [i+1, hand_color])

func toggle_hand_windows():
	"""Toggle visibility of all floating hand windows"""
	var any_visible = false
	
	# Check if any windows are currently visible
	for window in floating_hands:
		if window and window.visible:
			any_visible = true
			break
	
	# Toggle all windows to opposite state
	var new_visibility = not any_visible
	for window in floating_hands:
		if window:
			window.visible = new_visibility
	
	print("Hand windows %s" % ("shown" if new_visibility else "hidden"))

func toggle_single_domino_mode():
	"""Toggle single domino display mode for all trains"""
	var current_mode = false
	if player_trains[0] and player_trains[0].has_method("get"):
		current_mode = player_trains[0].show_single_domino
	
	var new_mode = not current_mode
	
	# Toggle for Mexican Train
	if mexican_train and mexican_train.has_method("set_single_domino_mode"):
		mexican_train.set_single_domino_mode(new_mode)
	
	# Toggle for all player trains
	for train in player_trains:
		if train and train.has_method("set_single_domino_mode"):
			train.set_single_domino_mode(new_mode)
	
	print("Single domino mode %s" % ("enabled" if new_mode else "disabled"))

func _input(event):
	"""Handle input for theme cycling and other controls"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_C:
				cycle_theme()
			KEY_H:
				toggle_hand_windows()
			KEY_S:
				toggle_single_domino_mode()			
			KEY_D:
				print_layout_debug_info()
				analyze_space_usage()
				suggest_layout_optimizations()
			KEY_ESCAPE:
				get_tree().quit()
				
func print_layout_debug_info():
	"""Print detailed size and position information for all UI elements"""
	print("\n=== LAYOUT DEBUG INFO ===")
	
	# Main window info
	var window_size = get_viewport().get_visible_rect().size
	print("Window size: %s" % window_size)
	
	# Main container sizes
	print("\n--- Main Containers ---")
	print("Root Control size: %s, position: %s" % [size, position])
	
	var background = $Background
	if background:
		print("Background size: %s, position: %s" % [background.size, background.position])
	
	# Game board elements
	print("\n--- Game Board Elements ---")
	var game_board = $GameBoard
	if game_board:
		print("GameBoard size: %s, position: %s" % [game_board.size, game_board.position])
	
	if boneyard:
		print("Boneyard size: %s, position: %s, global_pos: %s" % [boneyard.size, boneyard.position, boneyard.global_position])
		print("Boneyard custom_minimum_size: %s" % boneyard.custom_minimum_size)
	
	if central_station:
		print("CentralStation size: %s, position: %s, global_pos: %s" % [central_station.size, central_station.position, central_station.global_position])
		print("CentralStation custom_minimum_size: %s" % central_station.custom_minimum_size)
	
	if mexican_train:
		print("MexicanTrain size: %s, position: %s, global_pos: %s" % [mexican_train.size, mexican_train.position, mexican_train.global_position])
		print("MexicanTrain custom_minimum_size: %s" % mexican_train.custom_minimum_size)
	
	# Floating hand windows info
	print("\n--- Floating Hand Windows ---")
	print("Number of floating windows: %d" % floating_hands.size())
	
	for i in range(min(4, floating_hands.size())):  # Show first 4 hands to avoid spam
		if floating_hands[i]:
			var window = floating_hands[i]
			print("Floating Window %d size: %s, position: %s, title: %s" % [i+1, window.size, window.position, window.title])
	
	# Player trains
	print("\n--- Player Trains ---")
	var trains_container = $PlayerTrains
	if trains_container:
		print("PlayerTrains container size: %s, position: %s" % [trains_container.size, trains_container.position])
	
	for i in range(min(4, player_trains.size())):  # Show first 4 trains to avoid spam
		if player_trains[i]:
			print("Train %d size: %s, position: %s, custom_min: %s" % [i+1, player_trains[i].size, player_trains[i].position, player_trains[i].custom_minimum_size])
	
	# UI elements
	print("\n--- UI Elements ---")
	if title_label:
		print("Title size: %s, position: %s" % [title_label.size, title_label.position])
	
	if instructions_label:
		print("Instructions size: %s, position: %s" % [instructions_label.size, instructions_label.position])
	
	print("=== END LAYOUT DEBUG ===\n")

func analyze_space_usage():
	"""Analyze how space is being used and suggest optimizations"""
	print("\n=== SPACE USAGE ANALYSIS ===")
	
	var window_size = get_viewport().get_visible_rect().size
	var total_area = window_size.x * window_size.y
	
	print("Total window area: %d pixels" % total_area)
	
	# Calculate space used by floating hand windows
	print("Floating hand windows: %d windows created" % floating_hands.size())
	
	var total_floating_window_area = 0
	for window in floating_hands:
		if window:
			var window_area = window.size.x * window.size.y
			total_floating_window_area += window_area
	
	if total_floating_window_area > 0:
		var floating_percent = (total_floating_window_area / total_area) * 100
		print("Floating Windows total area: %d pixels (%.1f%% of screen)" % [total_floating_window_area, floating_percent])
	
	# Calculate used space by major containers
	var trains_container = $PlayerTrains
	var game_board = $GameBoard
	
	if trains_container:
		var trains_area = trains_container.size.x * trains_container.size.y
		var trains_percent = (trains_area / total_area) * 100
		print("Player Trains area: %d pixels (%.1f%% of screen)" % [trains_area, trains_percent])
	
	if game_board:
		var board_area = game_board.size.x * game_board.size.y
		var board_percent = (board_area / total_area) * 100
		print("Game Board area: %d pixels (%.1f%% of screen)" % [board_area, board_percent])
	
	# Check floating hand window sizes
	print("\n--- Individual Element Analysis ---")
	print("Floating hand windows analysis:")
	for i in range(floating_hands.size()):
		if floating_hands[i]:
			var window = floating_hands[i]
			print("Floating Window %d: %s at %s" % [i+1, window.size, window.position])
	
	# Check train sizes
	var total_train_height = 0
	for i in range(player_trains.size()):
		if player_trains[i]:
			total_train_height += player_trains[i].size.y + 10  # 10 for spacing
	
	print("Total train stack height: %d pixels" % total_train_height)
	if trains_container:
		var available_height = trains_container.size.y
		print("Available trains container height: %d pixels" % available_height)
		if total_train_height > available_height:
			print("WARNING: Trains are too tall for container!")
		else:
			print("Trains fit with %d pixels to spare" % (available_height - total_train_height))
	
	print("=== END SPACE ANALYSIS ===\n")

func suggest_layout_optimizations():
	"""Suggest specific layout optimizations based on current sizing"""
	print("\n=== LAYOUT OPTIMIZATION SUGGESTIONS ===")
	
	var window_size = get_viewport().get_visible_rect().size
	
	# Check if we can reduce hand/train sizes
	var current_hand_width = 290  # From scene file
	var current_train_width = 290  # Estimated
	
	var suggested_hand_width = min(250, window_size.x * 0.18)  # 18% of screen width
	var suggested_train_width = min(250, window_size.x * 0.18)  # 18% of screen width
	
	if current_hand_width > suggested_hand_width:
		print("• Reduce hand width from %d to %d pixels (save %d pixels)" % [current_hand_width, suggested_hand_width, current_hand_width - suggested_hand_width])
	
	if current_train_width > suggested_train_width:
		print("• Reduce train width from %d to %d pixels (save %d pixels)" % [current_train_width, suggested_train_width, current_train_width - suggested_train_width])
	
	# Check hand heights
	var current_hand_height = 70  # From scene file
	var suggested_hand_height = 50  # Smaller for more compact layout
	
	if current_hand_height > suggested_hand_height:
		var savings_per_hand = current_hand_height - suggested_hand_height
		var total_savings = savings_per_hand * 8
		print("• Reduce hand height from %d to %d pixels (save %d pixels total)" % [current_hand_height, suggested_hand_height, total_savings])
	
	# Check train heights
	var current_train_height = 50  # From custom_minimum_size
	var suggested_train_height = 40  # Even smaller for trains
	
	if current_train_height > suggested_train_height:
		var savings_per_train = current_train_height - suggested_train_height
		var total_savings = savings_per_train * 8
		print("• Reduce train height from %d to %d pixels (save %d pixels total)" % [current_train_height, suggested_train_height, total_savings])
	
	# Suggest more compact spacing
	print("• Reduce spacing between hands/trains from 10px to 5px")
	print("• Consider making game board area more compact")
	print("• Move instruction text to a smaller overlay or status bar")
	
	print("=== END OPTIMIZATION SUGGESTIONS ===\n")
