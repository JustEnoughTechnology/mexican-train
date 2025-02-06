class_name DominoData extends Resource
## Basic data resource for [class DominoSprite]

## Prefers to have an autoload [class GameState] containing the maximum number 
## of dots each side of the domino can have. does basic check and clamps the values to 6 if no other guidance

var dots: Vector2i 
var is_face_up:=false
## Enforces the convention that the smaller number of dots is on the left and that they are not larger than the max value allowed

func set_dots(p_left:int,p_right:int):
	var clamp_to :int = (
		GameState.get("MAX_DOTS") 
		if GameState.get("MAX_DOTS") != null 
		else 6
		)
	
	dots = Vector2i(clampi(min(p_left,p_right),0,clamp_to),clampi(max(p_left,p_right),0,clamp_to))
	
func _init(p_left:int,p_right:int):
	set_dots(p_right,p_right)
		
