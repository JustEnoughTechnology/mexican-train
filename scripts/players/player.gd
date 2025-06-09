class_name Player extends Node2D

## Player class for Mexican Train dominoes game
## Manages player data including name, hand, train, color, and game state

# Player data
var player_number: int = 0
var player_name: String = ""
var player_color: Color = Color.WHITE
var is_human: bool = true  # vs AI player

# Game components
var hand: Hand = null
var train: Train = null

# Game state
var has_placed_engine: bool = false
var is_active_turn: bool = false
var domino_count: int = 0

# Preloaded scenes
var hand_scene: PackedScene = preload("res://scenes/hand/hand.tscn")
var train_scene: PackedScene = preload("res://scenes/train/train.tscn")

func _ready() -> void:
	# Initialize player components when ready
	pass

func initialize_player(p_number: int, p_name: String = "", p_color: Color = Color.WHITE, p_is_human: bool = true) -> void:
	"""Initialize the player with all necessary data and components"""
	player_number = p_number
	player_color = p_color
	is_human = p_is_human
	
	# Generate unique name if not provided
	if p_name.is_empty():
		var player_name_util = preload("res://scripts/util/player_name_util.gd")
		player_name = player_name_util.get_unique_player_name(player_number)
	else:
		player_name = p_name
	
	# Create hand and train components
	await create_hand()
	await create_train()
	
	print("Player %d initialized: %s (Color: %s, Human: %s)" % [player_number, player_name, player_color, is_human])

func create_hand() -> void:
	"""Create and configure the player's hand"""
	if hand:
		hand.queue_free()
	
	hand = hand_scene.instantiate()
	hand.name = "Player%dHand" % player_number
	hand.bg_color = player_color
	
	# Add hand to the scene tree (parent will be set by the scene manager)
	add_child(hand)
	
	# Wait for hand to be ready before setting label
	await hand.ready
	hand.set_label_text("%s's Hand" % player_name)
	
	# Connect hand signals
	if hand.has_signal("domino_count_changed"):
		hand.domino_count_changed.connect(_on_hand_domino_count_changed)

func create_train() -> void:
	"""Create and configure the player's train"""
	if train:
		train.queue_free()
	
	train = train_scene.instantiate()
	train.name = "Player%dTrain" % player_number
	train.bg_color = player_color
	
	# Add train to the scene tree (parent will be set by the scene manager)
	add_child(train)
	
	# Wait for train to be ready before setting label
	await train.ready
	train.set_label_text("%s's Train" % player_name)
	
	# Connect train signals
	if train.has_signal("domino_added"):
		train.domino_added.connect(_on_train_domino_added)

func get_hand() -> Hand:
	"""Get the player's hand component"""
	return hand

func get_train() -> Train:
	"""Get the player's train component"""
	return train

func get_player_name() -> String:
	"""Get the player's name"""
	return player_name

func get_player_color() -> Color:
	"""Get the player's color"""
	return player_color

func get_player_number() -> int:
	"""Get the player's number"""
	return player_number

func update_domino_count() -> void:
	"""Update the cached domino count"""
	if hand and hand.has_method("get_domino_count"):
		domino_count = hand.get_domino_count()

func set_active_turn(active: bool) -> void:
	"""Set whether it's this player's turn"""
	is_active_turn = active
	
	# Visual feedback for active player (optional)
	if hand:
		hand.modulate = Color.YELLOW if active else Color.WHITE
	if train:
		train.modulate = Color.YELLOW if active else Color.WHITE

# Signal handlers
func _on_hand_domino_count_changed() -> void:
	"""Handle when hand domino count changes"""
	update_domino_count()
	print("Player %s: Hand now has %d dominoes" % [player_name, domino_count])

func _on_train_domino_added() -> void:
	"""Handle when a domino is added to the train"""
	var train_length = train.get_domino_count() if train and train.has_method("get_domino_count") else 0
	print("Player %s: Train extended to %d dominoes" % [player_name, train_length])
