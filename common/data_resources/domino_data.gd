class_name DominoData extends Resource
## Basic data resource for [class DominoSprite]

## Prefers to have an autoload [class GameState] containing the maximum number 
## of dots each side of the domino can have. does basic check and clamps the values to 6 if no other guidance


var dots: Vector2i 
var is_face_up:bool   ## [constant true] if dots are visible
var is_flipped:= false ## [constant true] if the domino has been rotated 180 degrees

## Enforces the convention that the smaller number of dots is on the left 
## unless the domino [param is_flipped]
func _init(p_left:int,p_right:int,p_is_face_up:bool):
	var clamp_to :int = (
		GameState.get("MAX_DOTS") 
		if GameState.get("MAX_DOTS") != null 
		else 6
		)
		
	## smaller on the left
	if p_left <= p_right:
		dots[0] = p_left
		dots[1] = p_right
	else:
		dots[1] = p_left
		dots[0] = p_right
	
	## enforce [constant MAX_DOTS]
	dots = Vector2(clampi(dots[0],0,clamp_to),clampi(dots[1],0,clamp_to))
	
	is_face_up = p_is_face_up
	
