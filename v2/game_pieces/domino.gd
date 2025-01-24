class_name Domino
extends ColorRect

signal mouse_left_pressed(p_domino:Domino)
signal mouse_right_pressed(p_domino:Domino)
signal mouse_left_released(p_domino:Domino)
signal mouse_right_released(p_domino:Domino)

@onready var d_sprite:DominoSprite = $DominoSprite

func set_face_up(p_face_up:bool):
	d_sprite.set_face_up(p_face_up)
	
func get_dots()->Vector2i:
	return d_sprite.get_dots()

func set_dots(p_left:int,p_right:int)->void:
	d_sprite.set_dots(p_left,p_right)

func show_dots():
	d_sprite.show_dots()
	
func toggle_dots():
	d_sprite.toggle_dots()

func hide_dots():
	d_sprite.hide_dots()
	
func get_domino_size() -> Vector2:
	return d_sprite.get_domino_size()
