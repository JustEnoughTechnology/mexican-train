class_name DominoControl
extends Control
signal domino_clicked(p_domino:DominoControl)

func _ready() -> void:
	$DominoNode2D.set_dots(randi_range(0,GameState.MAX_DOTS+1),randi_range(0,GameState.MAX_DOTS+1))

func _on_domino_node_2d_clicked(_domino: DominoNode2D) -> void:
	domino_clicked.emit(self)

func show_dots():
	$DominoNode2D.show_dots()
	
func toggle_dots():
	$DominoNode2D.toggle_dots()

func hide_dots():
	$DominoNode2D.hide_dots()
func get_domino_size() -> Vector2:
	return $DominoNode2D.get_domino_size()
	
	
