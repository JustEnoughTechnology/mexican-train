class_name Domino
extends Node2D
var _dots :Dictionary ={}
		
func set_dots(left:int,right:int):
	_dots[0] = left
	_dots[1] = right
	$"0/Label".text = str(_dots[0])
	$"1/Label".text = str(_dots[1])
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"0/Label".text = str(_dots[0])
	$"1/Label".text = str(_dots[1])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
