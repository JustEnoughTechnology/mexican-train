class_name DominoNode2D extends Node2D

var data:DominoData
var face_up :bool = true
var draggable := false
var is_inside_droppable:= false
var body_ref

@onready var left := $"Area2D/CollisionShape2D/GridContainer/0"
@onready var right := $"Area2D/CollisionShape2D/GridContainer/1"
@onready var container :=  $"Area2D/CollisionShape2D/GridContainer"
@onready var sep :=$Area2D/CollisionShape2D/GridContainer/Line2D

func _init(p_left:int=0,p_right:int=0,p_face_up:bool=true,p_is_flipped:bool=false):
	data =  DominoData.new(p_left,p_right,p_face_up,p_is_flipped)
	
func set_face_up(p_face_up:bool):
	data.is_face_up = p_face_up

func get_domino_size()->Vector2:
	return container.size
		
func show_dots(on:bool=true):
	if on:
		left.set_texture( load("res://2d/tiles/domino_dots_%d.tres"%data.dots[0]))
		right.set_texture( load("res://2d/tiles/domino_dots_%d.tres"%data.dots[1]))
		data.is_face_up = true
		sep.visible = true
	else:
		left.set_texture(load("res://2d/tiles/domino_dots_0.tres"))
		right.set_texture(load("res://2d/tiles/domino_dots_0.tres"))
		data.is_face_up = false
		sep.visible = false

func get_dots()->Vector2:
	return data.dots

func set_dots(p_left:int,p_right:int):
	data.dots[0] = p_left
	data.dots[1] = p_right

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	show_dots(data.is_face_up)
	
func toggle_dots() -> void:
	show_dots(data.is_face_up)
