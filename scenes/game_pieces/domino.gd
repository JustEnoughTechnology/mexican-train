class_name Domino extends ColorRect
@onready var data: DominoData
@onready var back := $CenterContainer/DominoBack
@onready var front := $CenterContainer/DominoFront
@onready var container := $CenterContainer
<<<<<<<< HEAD:scripts/game_pieces/domino.gd
@onready var imgpath :="res://assets/tiles/domino-%d-%d.svg"
========
@onready var imgpath :="res://common/tiles/2d/domino-%d-%d.svg"
>>>>>>>> 8997d63e58dfdd559b24b196f66b00a42b1399ee:scenes/game_pieces/domino.gd
@onready var old_modulate := modulate
@onready var is_highlighted := false

signal mouse_right_pressed(p_domino: Domino)
<<<<<<<< HEAD:scripts/game_pieces/domino.gd
@warning_ignore("unused_signal")
signal dragged_away (p_domino:Domino)
========
signal mouse_left_released(p_domino: Domino)
signal mouse_right_released(p_domino: Domino)
#signal dragged_away (p_domino:Domino)
>>>>>>>> 8997d63e58dfdd559b24b196f66b00a42b1399ee:scenes/game_pieces/domino.gd

func _ready() -> void:
	container.pivot_offset = container.size / 2
	set_dots(data.dots[0],data.dots[1])
	set_face_up(data.is_face_up)

func _init(left:=0,right:=0) -> void:
	data = DominoData.new(left, right)
	
func flip():
	rotation_degrees += 180.0	
func flip90():
	rotation_degrees += 90.0

<<<<<<<< HEAD:scripts/game_pieces/domino.gd
@warning_ignore("unused_parameter")
func _can_drop_data(at_position: Vector2, p_data: Variant) -> bool:
========
func _can_drop_data(_at_position: Vector2, _p_data: Variant) -> bool:
>>>>>>>> 8997d63e58dfdd559b24b196f66b00a42b1399ee:scenes/game_pieces/domino.gd
	return false
	
func get_preview() -> Domino:
	return self.duplicate()

func _get_drag_data(_at_position: Vector2) -> Variant:
	set_drag_preview(get_preview())
	return self
	
func highlight(is_on: bool = true):
	modulate = old_modulate if !is_on else Color(0.9, 0.9, 0.9, 0.75)
	is_highlighted = is_on

func set_face_up(is_on:bool = true):
	data.is_face_up = is_on
	front.visible = data.is_face_up
	
	
func get_dots() -> Vector2i:
	return data.dots

func set_dots(p_left: int, p_right: int) -> void:
	data.dots = Vector2i(max(p_left, p_right),min(p_left,p_right))
		
	front.set_texture(load(imgpath%[data.dots[0],data.dots[1]]))

func toggle_dots():
	set_face_up(!data.is_face_up)

func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_right"):
		mouse_right_pressed.emit(self)
	else:
		gui_input.emit(event)
