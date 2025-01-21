class_name MexicanTrain extends Node2D
@onready var boneyard:BoneYard = $BoneYard

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	boneyard.populate(12,true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
