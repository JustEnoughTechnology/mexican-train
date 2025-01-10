extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$DominoNode2D.set_dots(2,11)
	$DominoNode2D._show_dots()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
