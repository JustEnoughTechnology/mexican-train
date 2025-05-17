class_name GameBoard extends Node2D
@onready var bone_yard := $BoneYard
@onready var trains := $Station/Trains

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#$BoneYard.set_size(get_window().size*0.75)
	$BoneYard.populate(12,true) 
	$BoneYard.shuffle()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
