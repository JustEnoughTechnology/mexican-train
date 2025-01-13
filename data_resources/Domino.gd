class_name Domino
extends Resource
var dots: Vector2i 
var face_up:bool

func _init(p_left:int,p_right:int,p_face_up:bool):
	dots[0] = p_left
	dots[1] = p_right
	face_up = p_face_up
