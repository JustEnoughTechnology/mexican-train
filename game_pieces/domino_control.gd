class_name DominoControl
extends Control
signal domino_clicked(p_domino:DominoControl)

func _on_domino_clicked(p_domino: DominoNode2D) -> void:
	p_domino.domino_clicked.emit()

func _ready() -> void:
	$DominoNode2D.set_dots(12,11)
	print (self.get_property_list())


func _on_domino_node_2d_clicked(domino: DominoNode2D) -> void:
	print (  _on_domino_node_2d_clicked)
	
