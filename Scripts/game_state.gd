extends Node

const DEFAULT_PORT = 16543
const MAX_PLAYERS = 10


# Called when the node enters the scene tree for the first time.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func _init() -> void:
	debug_signal.connect(handle_debug_signal)
	
func handle_debug_signal(signal_message:String):
	print ("caught signal: %s"%signal_message)
