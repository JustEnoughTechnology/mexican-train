class_name DominoNode2D extends Node2D

@export var  domino :Domino = preload("res://data_resources/domino.tres")
signal domino_clicked(domino:DominoNode2D)

var face_up :bool = true

func get_domino_size()->Vector2:
	return $Area2D/CollisionShape2D/GridContainer.size
		
func show_dots():
	
	$"Area2D/CollisionShape2D/GridContainer/0".set_texture( load("res://tiles/domino_dots_%d.tres"%domino.dots[0]))
	$"Area2D/CollisionShape2D/GridContainer/1".set_texture( load("res://tiles/domino_dots_%d.tres"%domino.dots[1]))
	face_up = true

func hide_dots():
	$"Area2D/CollisionShape2D/GridContainer/0/Label".set_texture(load("res://tiles/domino_dots_0.tres"))
	$"Area2D/CollisionShape2D/GridContainer/1/Label".set_texture(load("res://tiles/domino_dots_0.tres"))
	face_up = false
		
func set_dots(left:int,right:int):
	domino.dots[0] = left
	domino.dots[1] = right
	show_dots()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if domino.dots.is_empty():
		set_dots(0,0)
	else:
		set_dots(domino.dots[0],domino.dots[1])
	self.show_dots()
	
func toggle_dots() -> void:
	if face_up:
		hide_dots()
	else:
		show_dots()

func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed( "domino_clicked"):
		domino_clicked.emit(self)
