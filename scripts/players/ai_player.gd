class_name AIPlayer extends Player

## AI Player for Mexican Train dominoes game
## Basic AI that can pass turns - designed for testing and filling empty slots

# AI state
var ai_decision_delay: float = 1.0  # Delay before AI makes decisions
var can_play: bool = false

func _ready() -> void:
	super._ready()
	is_human = false

func initialize_ai_player(p_number: int, p_name: String = "", p_color: Color = Color.GRAY) -> void:
	"""Initialize AI player with AI-specific settings"""
	if p_name.is_empty():
		p_name = "AI Player %d" % p_number
	
	await initialize_player(p_number, p_name, p_color, false)
	print("AI Player %d initialized: %s" % [player_number, player_name])

func take_turn() -> void:
	"""AI's turn logic - basic implementation just passes"""
	print("AI Player %s taking turn..." % player_name)
	
	# Add a small delay to make AI decisions feel more natural
	await get_tree().create_timer(ai_decision_delay).timeout
	
	# For now, AI always passes (basic implementation)
	# TODO: Implement actual domino playing logic
	pass_turn()

func pass_turn() -> void:
	"""AI passes their turn"""
	print("AI Player %s passes their turn" % player_name)
	
	# Emit signal that turn is complete (if game system needs it)
	if has_signal("turn_completed"):
		emit_signal("turn_completed")

func can_make_move() -> bool:
	"""Check if AI can make any valid moves"""
	# For basic implementation, always return false (AI always passes)
	# TODO: Implement logic to check if AI has playable dominoes
	return false

func get_playable_dominoes() -> Array[Domino]:
	"""Get list of dominoes the AI can play"""
	# TODO: Implement logic to find valid dominoes from hand
	return []

func evaluate_move(domino: Domino, target_location: String) -> int:
	"""Evaluate the quality of a potential move (for future AI improvement)"""
	# TODO: Implement scoring logic for move evaluation
	return 0

func set_difficulty(level: String) -> void:
	"""Set AI difficulty level - for future expansion"""
	match level:
		"easy":
			ai_decision_delay = 2.0
		"medium":
			ai_decision_delay = 1.5
		"hard":
			ai_decision_delay = 1.0
		_:
			ai_decision_delay = 1.0
	
	print("AI Player %s difficulty set to: %s" % [player_name, level])

# Override set_active_turn to handle AI automatically
func set_active_turn(active: bool) -> void:
	super.set_active_turn(active)
	
	if active and not is_human:
		# AI automatically takes turn when it becomes active
		call_deferred("take_turn")
