class_name PlayerTrain_old
extends Area2D

func add_domino(p_domino:Domino):
	$Dominos.add_child(p_domino)
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
