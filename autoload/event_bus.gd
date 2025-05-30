class_name event_bus extends Node
@warning_ignore("unused_signal")
signal domino_selected(p_domino:Domino,p_source)
@warning_ignore("unused_signal")
signal domino_dropped(p_domino:Domino,p_dest)
@warning_ignore("unused_signal")
signal domino_rejected(p_domino:Domino,p_dest)
@warning_ignore("unused_signal")
signal train_enabled(train)
@warning_ignore("unused_signal")
signal train_disabled(train)
@warning_ignore("unused_signal")
signal one_left (player)
@warning_ignore("unused_signal")
signal winner(player)
#signal mouse_over_domino(p_domino:Domino)
#signal mouse_left_domino(p_domino:Domino)
#signal mouse_over_domino_area(p_area:DominoArea)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")func _process(delta: float) -> void:
	pass
