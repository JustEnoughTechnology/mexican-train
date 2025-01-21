class_name DominoNode2D extends Node2D

var domino:Domino
var face_up :bool = true
var draggable := false
var is_inside_droppable:= false
var body_ref

@onready var left := $"Area2D/CollisionShape2D/GridContainer/0"
@onready var right := $"Area2D/CollisionShape2D/GridContainer/1"
@onready var container :=  $"Area2D/CollisionShape2D/GridContainer"
@onready var sep :=$Area2D/CollisionShape2D/GridContainer/Line2D
signal domino_clicked(p_domino:DominoNode2D)
signal domino_right_clicked(p_domino:DominoNode2D)
func _init(p_left:int=0,p_right:int=0,p_face_up:bool=true):
	domino =  Domino.new(p_left,p_right,p_face_up)
	
func set_face_up(p_face_up:bool):
	face_up = p_face_up

func get_domino_size()->Vector2:
	return container.size
		
func show_dots():
	left.set_texture( load("res://tiles/domino_dots_%d.tres"%domino.dots[0]))
	right.set_texture( load("res://tiles/domino_dots_%d.tres"%domino.dots[1]))
	face_up = true
	sep.visible = true

func hide_dots():
	left.set_texture(load("res://tiles/domino_dots_0.tres"))
	right.set_texture(load("res://tiles/domino_dots_0.tres"))

	face_up = false
	sep.visible = false

func get_dots()->Vector2:
	return domino.dots

func set_dots(p_left:int,p_right:int):
	domino.dots[0] = p_left
	domino.dots[1] = p_right

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if face_up:
		show_dots()
	else:
		hide_dots()

func toggle_dots() -> void:
	if face_up:
		hide_dots()
	else:
		show_dots()
func _on_area_2d_mouse_entered():
	if not GameState.is_dragging:
		draggable = true
		scale = Vector2(1.05,1.05)
		
func _on_area_2d_mouse_exited():
	if not GameState.is_dragging:
		draggable = false
		scale=Vector2(1,1)
		
func _on_area_2d_body_entered(p_body:StaticBody2D):
	if p_body.is_in_group('dropable'):
		is_inside_droppable = true
		if p_body.has_method("highlight"):
			p_body.highlight(true)
			
		body_ref = p_body
		

func _on_area_2d_body_exited(p_body:StaticBody2D):
	if p_body.is_in_group('dropable'):
		is_inside_droppable = false
		if p_body.has_method('highlight'):
			p_body.highlight(false)
	
	
	
func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed( "domino_clicked"):
		domino_clicked.emit(self)
	else:
		if event.is_action("Domino_right_clicked") :
			domino_right_clicked.emit(self)
