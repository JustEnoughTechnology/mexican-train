class_name DominoControl
extends Control
signal domino_clicked(p_domino:DominoControl)
signal domino_right_clicked(p_domino:DominoControl)

func set_face_up(p_face_up:bool):
	$DominoNode2D.set_face_up(p_face_up)
	
func _ready() -> void:
	pass
func get_dots()->Vector2i:
	return $DominoNode2D.get_dots()

func set_dots(p_left:int,p_right:int)->void:
	$DominoNode2D.set_dots(p_left,p_right)

func _on_domino_node_2d_clicked(_p_domino) -> void:
	domino_clicked.emit(self)

func show_dots():
	$DominoNode2D.show_dots()
	
func toggle_dots():
	$DominoNode2D.toggle_dots()

func hide_dots():
	$DominoNode2D.hide_dots()
	
func get_domino_size() -> Vector2:
	return $DominoNode2D.get_domino_size()

func _on_domino_node_2d_domino_right_clicked(p_domino: DominoNode2D) -> void:
	domino_right_clicked.emit(self) # Replace with function body.
