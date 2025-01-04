class_name DominoNode2D extends Node2D
var _dots :Dictionary ={}
		
func set_dots(left:int,right:int):
	_dots["0"] = left
	_dots["1"] = right
	$"0/Label".text = str(_dots["0"])
	$"1/Label".text = str(_dots["1"])
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !_dots.has("0"):
		set_dots(0,0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
