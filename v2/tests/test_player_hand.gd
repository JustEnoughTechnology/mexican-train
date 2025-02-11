extends Node2D
var current_domino:Domino
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_player_hand_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_left") :
		if $Container.get_child_count() > 0:
			current_domino = $Container.get_child(0)
			$PlayerHand.add_domino(current_domino)
	elif event.is_action_pressed("mouse_right"):
		if $PlayerHand.get_domino_count() >0 :
			current_domino = $PlayerHand.get_domino(-1)
			$PlayerHand.move_domino(current_domino,$Container)
			
					
