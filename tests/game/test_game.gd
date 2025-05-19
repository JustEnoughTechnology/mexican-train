extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$BoneYard.set_size(get_window().size*0.75)
	$Train.set_position($BoneYard.position+Vector2(0.0,$BoneYard.size.y))
	$Hand.set_position($Train.position+Vector2(0.0,$Train.size.y))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
