class_name DominoNode2Dc extends Area2D

@export var  domino :Domino = preload("res://data_resources/Domino.tres")
signal show_domino_dots
signal hide_domino_dots

func get_size()->Vector2:
	return $GridContainer.size
	
	
func _show_dots():
	$"GridContainer/0/Label".visible = true
	$"GridContainer/0/Label".visible = true
	
func _hide_dots():
	$"GridContainer/0/Label".visible = false
	$"GridContainer/0/Label".visible = false
		
func set_dots(left:int,right:int):
	domino.dots[0] = left
	domino.dots[1] = right
	
	$"GridContainer/0/Label".text = str(domino.dots[0])
	$"GridContainer/1/Label".text = str(domino.dots[1])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.hide_domino_dots.connect(_hide_dots)	
	self.show_domino_dots.connect(_show_dots)
	
	if domino.dots.is_empty():
		set_dots(0,0)
	else:
		set_dots(domino.dots[0],domino.dots[1])
	_show_dots()
	
