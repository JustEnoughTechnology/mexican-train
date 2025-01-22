class_name DominoSprite extends Sprite2D

@onready var data:DominoData
@onready var left := $"Area2D/CollisionShape2D/GridContainer/0"
@onready var right := $"Area2D/CollisionShape2D/GridContainer/1"
@onready var container :=  $"Area2D/CollisionShape2D/GridContainer"
@onready var sep :=$Area2D/CollisionShape2D/GridContainer/Line2D

func _init(p_left:int=0,p_right:int=0,p_face_up:bool=true,p_is_flipped:bool=false):
	data = DominoData.new(p_left,p_right,p_face_up,p_is_flipped)

func _ready() -> void:
	container.pivot_offset = container.size / 2
	
	if data.is_face_up:
		show_dots()
	else:
		hide_dots()

func flip():
	data.is_flipped = ! data.is_flipped
	container.rotation_degrees = float((int(container.rotation_degrees)+180)%360)
		
func set_face_up(p_is_face_up:bool):
	data.is_face_up = p_is_face_up

func get_domino_size()->Vector2:
	return container.size
		
func show_dots():
	left.set_texture( load("res://2d/tiles/domino_dots_%d.tres"%data.dots[0]))
	right.set_texture( load("res://2d/tiles/domino_dots_%d.tres"%data.dots[1]))
	set_face_up( true)
	sep.visible = true

func hide_dots():
	left.set_texture(load("res://2d/tiles/domino_dots_0.tres"))
	right.set_texture(load("res://2d/tiles/domino_dots_0.tres"))

	set_face_up( false)
	sep.visible = false

func get_dots()->Vector2:
	return data.dots

func set_dots(p_left:int,p_right:int):
	data.dots[0] = p_left
	data.dots[1] = p_right
	if is_node_ready():
		if data.is_face_up:
			show_dots()
		else:
			hide_dots()

# Called when the node enters the scene tree for the first time.

func toggle_dots() -> void:
	if data.is_face_up:
		hide_dots()
	else:
		show_dots()
		
func _process(delta: float) -> void:
	pass		
