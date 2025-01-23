extends HFlowContainer

func _on_domino_control_2_domino_clicked(p_domino: DominoControl) -> void:
	print(p_domino.get_dots()) 
	# Replace with function body.
	p_domino.toggle_dots()
