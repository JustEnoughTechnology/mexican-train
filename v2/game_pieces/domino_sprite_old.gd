class_name DominoSpriteOld extends Sprite2D
## This is where the low level domino code lives. 
##
## Just the basics like face up/down, flipping lengthwise, highlighting, [br]
## and setting the number of dots

@onready var data: DominoData
@onready var left := $"Area2D/CollisionShape2D/GridContainer/0"
@onready var right := $"Area2D/CollisionShape2D/GridContainer/1"
@onready var container := $"Area2D/CollisionShape2D/GridContainer"
@onready var sep := $Area2D/CollisionShape2D/GridContainer/Line2D
@onready var old_modulate := modulate
@onready var is_highlighted := false


signal mouse_entered(p_domino: DominoSprite)	## 
signal mouse_exited(p_domino: DominoSprite)
signal mouse_right_pressed(p_domino: DominoSprite)
signal mouse_left_pressed(p_domino: DominoSprite)
signal mouse_right_released(p_domino: DominoSprite)
signal mouse_left_released(p_domino: DominoSprite)
signal gui_input(event:InputEvent)

func _init(p_left: int = 0, p_right: int = 0, p_face_up: bool = true):
	data = DominoData.new(p_left, p_right, p_face_up)

##
func _ready() -> void:
	container.pivot_offset = container.size / 2
	show_dots(data.is_face_up)
	
## 
func flip():
	data.is_flipped = not data.is_flipped
	container.rotation_degrees = float((int(container.rotation_degrees) + 180) % 360)

##		
func set_face_up(p_is_face_up: bool):
	data.is_face_up = p_is_face_up

##
func get_domino_size() -> Vector2:
	return container.size
		

##
func show_dots(on:bool=true):
	if on:
		left.set_texture(load("res://2d/tiles/domino_dots_%d.tres"%data.dots[0]))
		right.set_texture(load("res://2d/tiles/domino_dots_%d.tres"%data.dots[1]))
		set_face_up(true)
		sep.visible = true
	else:
		left.set_texture(load("res://2d/tiles/domino_dots_0.tres"))
		right.set_texture(load("res://2d/tiles/domino_dots_0.tres"))
		set_face_up(false)
		sep.visible = false


##
func get_dots() -> Vector2:
	return data.dots


## Enforces the convention that initially the domino is oriented so that smaller number of dots [br]
## is on the left. Also enforces that we can't set more than  
## Also enforces
func set_dots(p_left: int, p_right: int):
	data.dots[0] = p_left
	data.dots[1] = p_right
	if is_node_ready():
		show_dots(data.is_face_up)
		
##
func toggle_dots() -> void:
	show_dots(!data.is_face_up)


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("domino_left_clicked"):
		mouse_left_pressed.emit(self)
	elif event.is_action_released("domino_left_clicked"):
		mouse_left_released.emit(self)
	elif event.is_action_pressed("domino_right_clicked"):
		mouse_right_pressed.emit(self)
	elif event.is_action_released("domino_right_clicked"):
		mouse_right_released.emit(self)
	else:
		gui_input.emit(event)

func _on_mouse_entered() -> void:
	mouse_entered.emit(self)

func _on_mouse_exited() -> void:
	mouse_exited.emit(self)
	
func highlight(on: bool = true):
	modulate = old_modulate if !on else Color(0.9, 0.9, 0.9, 0.75)
	is_highlighted = on
