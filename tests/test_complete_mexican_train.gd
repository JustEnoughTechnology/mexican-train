extends Control

## Complete Mexican Train Game Test
## This scene integrates BoneYard, Hand, Station, and Train for a near-complete game experience

# Scene references
@onready var boneyard = $GameLayout/BoneYard
@onready var hand = $GameLayout/Hand  
@onready var station = $GameLayout/CenterArea/Station
@onready var train = $GameLayout/CenterArea/Train
@onready var status_label = $UI/StatusLabel
@onready var instructions_label = $UI/InstructionsLabel

# Game state
var game_started := false
var engine_domino_placed := false

func _ready() -> void:
	get_window().title = "Complete Mexican Train Game"
	get_window().mode = Window.MODE_MAXIMIZED
	
	# Initialize game components
	setup_game()
	
	# Connect signals
	connect_signals()
	
	# Enable drag-drop targets
	setup_drag_drop_targets()
	
	# Show initial instructions
	update_instructions()
	update_status("Game ready! Drag dominoes from boneyard to hand, then place the 6-6 engine domino in station.")

func setup_game() -> void:
	# Populate boneyard with all standard dominoes (0-0 to 6-6)
	if boneyard.has_method("populate"):
		boneyard.populate(6, false)  # Face down initially
		print("BoneYard populated with 28 dominoes (0-0 to 6-6)")
	
	# Initialize station as empty (waiting for 6-6 engine)
	if station.has_method("initialize_empty"):
		station.initialize_empty()
		print("Station initialized and ready for 6-6 engine domino")
	
	# Initialize train as empty
	if train.has_method("clear_train"):
		train.clear_train()
		print("Train initialized and ready")
	
	# Hand starts empty - players will drag dominoes from boneyard
	print("Hand ready for domino collection")

func connect_signals() -> void:
	# Connect boneyard signals
	if boneyard.has_signal("too_many_dominos"):
		boneyard.too_many_dominos.connect(_on_boneyard_too_many_dominos)
	
	# Connect hand signals
	if hand.has_signal("domino_count_changed"):
		hand.domino_count_changed.connect(_on_hand_domino_count_changed)
	
	# Connect station signals (if they exist)
	if station.has_signal("engine_domino_placed"):
		station.engine_domino_placed.connect(_on_engine_domino_placed)
	
	# Connect train signals (if they exist)
	if train.has_signal("domino_added"):
		train.domino_added.connect(_on_train_domino_added)

func setup_drag_drop_targets() -> void:
	"""Enable all necessary drag-drop targets"""
	# Enable hand as drop target
	if hand and hand.has_method("enable_drop_target"):
		hand.enable_drop_target()
		print("Hand enabled as drop target")
	
	# Enable train as drop target  
	if train and train.has_method("enable_drop_target"):
		train.enable_drop_target()
		print("Train enabled as drop target")
	
	# Station is enabled by default
	print("Station ready for drag-drop")

func update_instructions() -> void:
	var instructions = ""
	if not engine_domino_placed:
		instructions = """GAME SETUP:
1. Drag dominoes from the boneyard to your hand
2. Find any double domino (0-0, 1-1, 2-2, etc.) and drag it to the pink station to start the engine
3. Once the engine is placed, you can extend the train by matching dominoes

CONTROLS:
• Drag dominoes with mouse
• Right-click dominoes to flip face up/down
• Spacebar to rotate domino orientations
• Enter to toggle debug warnings"""
	else:
		instructions = """GAME IN PROGRESS:
• Engine domino is placed!
• Drag matching dominoes from your hand to extend the train
• Match the open end of the train (currently showing %s)
• Build the longest train possible!

CONTROLS:
• Drag dominoes with mouse
• Right-click dominoes to flip face up/down  
• Spacebar to rotate domino orientations""" % get_train_open_end_display()
	
	instructions_label.text = instructions

func get_train_open_end_display() -> String:
	if train and train.has_method("get_open_end"):
		var open_end = train.get_open_end()
		if open_end != -1:
			return str(open_end)
	return "unknown"

func update_status(message: String) -> void:
	# Check if status_label is still valid before accessing it
	if is_instance_valid(status_label):
		status_label.text = message
	print("[GAME STATUS] " + message)

# Signal handlers
func _on_boneyard_too_many_dominos(dot_count: int) -> void:
	update_status("Warning: Too many dominos requested (%d)" % dot_count)

func _on_hand_domino_count_changed() -> void:
	var count = hand.get_domino_count() if hand.has_method("get_domino_count") else 0
	update_status("Hand now has %d dominoes" % count)
	
	# Check if hand has the 6-6 domino needed for engine
	if not engine_domino_placed and count > 0:
		var has_double_six = check_hand_for_double_six()
		if has_double_six:
			update_status("Hand has %d dominoes including the 6-6 engine! Drag the 6-6 to the station." % count)
		else:
			update_status("Hand has %d dominoes. Look for the 6-6 engine domino." % count)

func check_hand_for_double_six() -> bool:
	if not hand or not hand.has_method("get_node"):
		return false
	
	var domino_container = hand.get_node("hand_layout/domino_container")
	if not domino_container:
		return false
	
	for domino in domino_container.get_children():
		if domino.has_method("get_dots"):
			var dots = domino.get_dots()
			if dots.x == 6 and dots.y == 6:
				return true
	return false

func _on_engine_domino_placed() -> void:
	engine_domino_placed = true
	game_started = true
	update_status("Engine domino (6-6) placed! Game started - now extend the train!")
	update_instructions()

func _on_train_domino_added() -> void:
	var train_length = train.get_domino_count() if train.has_method("get_domino_count") else 0
	update_status("Train extended! Length: %d dominoes. Open end: %s" % [train_length, get_train_open_end_display()])

# Input handling
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var keycode = event.keycode
		
		# Toggle debug warnings with Enter
		if keycode == KEY_ENTER or keycode == KEY_KP_ENTER:
			GameState.DEBUG_SHOW_WARNINGS = not GameState.DEBUG_SHOW_WARNINGS
			update_status("Debug warnings: %s" % ("ON" if GameState.DEBUG_SHOW_WARNINGS else "OFF"))
		
		# Handle spacebar for orientation changes
		elif keycode == KEY_SPACE:
			handle_spacebar_orientation_toggle()

func handle_spacebar_orientation_toggle() -> void:
	# Toggle orientation overlays for all visible dominoes
	toggle_orientation_overlays_in_container(boneyard, "boneyard_layout/domino_container")
	toggle_orientation_overlays_in_container(hand, "hand_layout/domino_container")
	toggle_orientation_overlays_in_container(train, "TopContainer/bg")
	
	# Also handle station if it has a domino
	if station and station.has_node("DominoContainer"):
		var station_container = station.get_node("DominoContainer")
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

# Game helper methods
func get_game_stats() -> Dictionary:
	var stats = {}
	stats["boneyard_count"] = boneyard.get_node("boneyard_layout/domino_container").get_child_count() if boneyard else 0
	stats["hand_count"] = hand.get_domino_count() if hand and hand.has_method("get_domino_count") else 0
	stats["train_count"] = train.get_domino_count() if train and train.has_method("get_domino_count") else 0
	stats["engine_placed"] = engine_domino_placed
	stats["game_started"] = game_started
	return stats

func print_game_stats() -> void:
	var stats = get_game_stats()
	print("=== GAME STATS ===")
	print("Boneyard: %d dominoes" % stats["boneyard_count"])
	print("Hand: %d dominoes" % stats["hand_count"])
	print("Train: %d dominoes" % stats["train_count"])
	print("Engine placed: %s" % stats["engine_placed"])
	print("Game started: %s" % stats["game_started"])
	print("==================")

# Debug method to simulate game progression (for testing)
func _on_debug_button_pressed() -> void:
	print_game_stats()
