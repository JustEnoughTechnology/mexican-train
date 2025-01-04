extends Node
var dominoes :Array[Domino] 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var domino:PackedScene = load("res://Scenes/domino.tscn")
	var domino1:Domino
	
	for i in range(13):
		for j in range(i+1):
			domino1 = domino.instantiate()
			domino1.name = "Domino "+str(i)
			domino1.set_dots(i,j)
			
			domino1.move_local_x( i*85)
			domino1.move_local_y(j*45)
			$"/root/Dominotest".add_child(domino1,true)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
