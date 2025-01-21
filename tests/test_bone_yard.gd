extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$BoneYard.populate(12,true)
	$BoneYard.shuffle()

func _on_bone_yard_domino_clicked(p_domino: DominoControl) -> void:
	print("clicked ",p_domino.get_dots())
	p_domino.toggle_dots()

func _on_bone_yard_domino_right_clicked(p_domino: DominoControl) -> void:
	print("right clicked ",p_domino.get_dots())
	$BoneYard.remove_domino(p_domino) 	
	p_domino.queue_free()
