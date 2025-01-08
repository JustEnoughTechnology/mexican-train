<<<<<<< HEAD
class_name DominoControl
extends Control
signal domino_clicked(domino:DominoControl)

func _gui_input(event: InputEvent) -> void:
	breakpoint
	if event == InputEventMouseButton:
		print("got mouse button")
		
func _on_domino_clicked(p_domino: DominoNode2D) -> void:
	print ("control clicked")
	p_domino.domino_clicked.emit()
	
	


func _on_mouse_entered() -> void:
	print ("mouse endtered control")
=======
extends Control
>>>>>>> 8123294 (adding domino as control)
