class_name DominoControl
extends PanelContainer
signal domino_clicked(p_domino:DominoControl)
signal domino_right_clicked(p_domino:DominoControl)
@onready var d_node:DominoNode2D = $DominoNode2D

func set_face_up(p_face_up:bool):
	d_node.set_face_up(p_face_up)
	
func get_dots()->Vector2i:
	return d_node.get_dots()

func set_dots(p_left:int,p_right:int)->void:
	d_node.set_dots(p_left,p_right)

func show_dots(on:bool=true):
	d_node.show_dots(on)
	
func toggle_dots():
	d_node.toggle_dots()
	
func get_domino_size() -> Vector2:
	return d_node.get_domino_size()

func _on_domino_node_2d_domino_right_clicked(p_domino: DominoNode2D) -> void:
	domino_right_clicked.emit(self) # Replace with function body.
	
func _on_domino_node_2d_clicked(_p_domino) -> void:
	domino_clicked.emit(self)	
