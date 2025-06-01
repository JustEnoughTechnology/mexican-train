extends Control
@export var dot_count:int = 18

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$BoneYard.set_size(get_window().size*0.85)
	$BoneYard.set_position(Vector2(0,0))
	
	$Train.set_position($BoneYard.position+Vector2(0.0,$BoneYard.size.y))
	$Hand.set_position($Train.position+Vector2(0.0,$Train.size.y))
	$BoneYard.populate(dot_count,true)
	if EngineDebugger.is_active():
		print($BoneYard.get_global_rect())

# Called every frame. 'delta' is the elapsed time since the previous frame.

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass

func _on_bone_yard_domino_outside_boneyard(p_domino: Domino) -> void:
	print(p_domino)


func _on_bone_yard_too_many_dominos(p_dot_count: int) -> void:
	print(p_dot_count) 
