class_name DominoNode2D extends Node2D

var domino:Domino = Domino.new()

signal domino_clicked(p_domino:DominoNode2D)

var face_up :bool = true

func get_domino_size()->Vector2:
	return $Area2D/CollisionShape2D/GridContainer.size
		
func show_dots():
	
	$"Area2D/CollisionShape2D/GridContainer/0".set_texture( load("res://tiles/domino_dots_%d.tres"%domino.dots[0]))
	$"Area2D/CollisionShape2D/GridContainer/1".set_texture( load("res://tiles/domino_dots_%d.tres"%domino.dots[1]))
	face_up = true

func hide_dots():
	$"Area2D/CollisionShape2D/GridContainer/0".set_texture(load("res://tiles/domino_dots_0.tres"))
	$"Area2D/CollisionShape2D/GridContainer/1".set_texture(load("res://tiles/domino_dots_0.tres"))
	face_up = false
		
func get_dots()->Vector2:
	return domino.dots

func set_dots(left:int,right:int):
	domino.dots[0] = left
	domino.dots[1] = right
	show_dots()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_dots(randi_range(0,GameState.MAX_DOTS),randi_range(0,GameState.MAX_DOTS))
	show_dots()
	
func toggle_dots() -> void:
	if face_up:
		hide_dots()
	else:
		show_dots()

func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed( "domino_clicked"):
		domino_clicked.emit(self)
