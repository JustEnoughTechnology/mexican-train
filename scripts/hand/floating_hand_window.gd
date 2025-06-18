extends Window

## Floating Hand Window
## A separate window for displaying a player's hand with drag and drop support

@onready var hand = $Hand
@onready var background = $Background

var player_name: String = ""
var player_number: int = 0
var main_scene: Node = null

signal hand_closed(player_number: int)
signal domino_drag_started(domino, from_window: Window)
signal domino_dropped_to_main(domino, drop_position: Vector2)

func _ready():
	# Connect window signals
	close_requested.connect(_on_close_requested)
	
	# Set up window properties
	always_on_top = false
	unresizable = false
		# Enable drag and drop
	if hand:
		hand.drag_started.connect(_on_hand_drag_started)
		hand.drop_completed.connect(_on_hand_drop_completed)

func setup_hand(p_player_name: String, p_player_number: int, p_main_scene: Node):
	"""Initialize the floating hand with player info and main scene reference"""
	player_name = p_player_name
	player_number = p_player_number
	main_scene = p_main_scene
	
	# Update window title
	title = "%s (P%d) - Hand" % [player_name, player_number]
		# Set up hand with player info
	if hand and hand.has_method("set_label_text"):
		hand.set_label_text("%s (P%d)" % [player_name, player_number])
	
	Logger.log_info(Logger.LogArea.UI, "Floating hand window set up for %s" % player_name)

func set_hand_color(color: Color):
	"""Set the background color for this hand window"""
	if background:
		background.color = color
	
	if hand and hand.has_method("set_background_color"):
		hand.set_background_color(color)
	elif hand:
		hand.bg_color = color
		hand.color = color

func populate_hand(dominoes: Array):
	"""Populate the hand with dominoes"""
	if hand and hand.has_method("populate"):
		hand.populate(dominoes)

func add_domino(domino):
	"""Add a domino to this hand"""
	if hand and hand.has_method("add_domino"):
		hand.add_domino(domino)

func remove_domino(domino):
	"""Remove a domino from this hand"""
	if hand and hand.has_method("remove_domino"):
		hand.remove_domino(domino)

func get_domino_count() -> int:
	"""Get the number of dominoes in this hand"""
	if hand and hand.has_method("get_domino_count"):
		return hand.get_domino_count()
	return 0

func _on_close_requested():
	"""Handle window close request"""
	Logger.log_info(Logger.LogArea.UI, "Hand window %d close requested" % player_number)
	hand_closed.emit(player_number)

func _on_hand_drag_started(domino):
	"""Handle when a domino starts being dragged from this hand"""
	Logger.log_debug(Logger.LogArea.UI, "Domino drag started from floating hand %d" % player_number)
	domino_drag_started.emit(domino, self)
	
	# Notify main scene about cross-window drag
	if main_scene and main_scene.has_method("handle_cross_window_drag"):
		main_scene.handle_cross_window_drag(domino, self)

func _on_hand_drop_completed(domino, drop_position: Vector2):
	"""Handle when a domino drop is completed"""
	Logger.log_debug(Logger.LogArea.UI, "Domino drop completed in floating hand %d" % player_number)
	
	# Convert local position to global for main scene
	var global_pos = Vector2(position) + drop_position
	domino_dropped_to_main.emit(domino, global_pos)

func set_window_position(pos: Vector2i):
	"""Set the window position"""
	position = pos

func get_window_position() -> Vector2i:
	"""Get the current window position"""
	return position

func minimize_window():
	"""Minimize this hand window"""
	mode = Window.MODE_MINIMIZED

func restore_window():
	"""Restore this hand window from minimized state"""
	mode = Window.MODE_WINDOWED

func is_minimized() -> bool:
	"""Check if this window is minimized"""
	return mode == Window.MODE_MINIMIZED
