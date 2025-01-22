extends Node2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$BoneYard.populate(12,true) # Replace with function body.
	$BoneYard.shuffle()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
