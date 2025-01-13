extends HBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$DominoNode2D.show_dots()
	$DominoNode2D2.show_dots()

func _on_domino_node_2d_domino_clicked(p_domino:DominoNode2D) -> void:
	p_domino.toggle_dots()
