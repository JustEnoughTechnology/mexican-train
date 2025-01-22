class_name Domino
extends PanelContainer
signal domino_clicked(p_domino:Domino)
signal domino_right_clicked(p_domino:Domino)
@onready var d_node:DominoSprite = $DominoSprite

func set_face_up(p_face_up:bool):
	d_node.set_face_up(p_face_up)
	
func get_dots()->Vector2i:
	return d_node.get_dots()

func set_dots(p_left:int,p_right:int)->void:
	d_node.set_dots(p_left,p_right)

func show_dots():
	d_node.show_dots()
	
func toggle_dots():
	d_node.toggle_dots()

func hide_dots():
	d_node.hide_dots()
	
func get_domino_size() -> Vector2:
	return d_node.get_domino_size()
