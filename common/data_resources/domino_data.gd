class_name DominoData
extends Resource
var dots: Vector2i 
var is_face_up:bool
var is_flipped:bool

func _init(p_left:int,p_right:int,p_is_face_up:bool,p_is_flipped:bool):
	
	dots[0] = p_left
	dots[1] = p_right
	is_face_up = p_is_face_up
	is_flipped = p_is_flipped
