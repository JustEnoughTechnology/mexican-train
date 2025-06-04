class_name DominoData extends Resource

# Orientation constants (single source of truth)
const ORIENTATION_LARGEST_LEFT = 0
const ORIENTATION_LARGEST_RIGHT = 1
const ORIENTATION_LARGEST_TOP = 2
const ORIENTATION_LARGEST_BOTTOM = 3
## Basic data resource for [class DominoSprite]

## Prefers to have an autoload [class GameState] containing the maximum number 
## of dots each side of the domino can have. does basic check and clamps the values to 6 if no other guidance

var dots: Vector2i 
var is_face_up := false
# Orientation property (matches Domino orientation constants)
var orientation: int = 0
## Stores dots as (x,y) coordinates where x and y represent the dot counts for each side
## For horizontal orientations: x=left side dots, y=right side dots
## For vertical orientations: x=top side dots, y=bottom side dots

func set_dots(p_left:int,p_right:int):
	var clamp_to :int = (
		GameState.get("MAX_DOTS") 
		if GameState.get("MAX_DOTS") != null 
		else 6
		)
	
	# Store dots as (x,y) where:
	# - For horizontal orientations: x=left_dots, y=right_dots  
	# - For vertical orientations: x=top_dots, y=bottom_dots
	# Do NOT sort them - preserve the order passed in
	dots = Vector2i(clampi(p_left,0,clamp_to), clampi(p_right,0,clamp_to))
	
func _init(p_left:int,p_right:int):
	set_dots(p_left,p_right)
		
