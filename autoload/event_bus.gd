class_name event_bus extends Node
signal domino_selected(p_domino:Domino,p_source)
signal domino_dropped(p_domino:Domino,p_dest)
signal domino_rejected(p_domino:Domino,p_dest)
signal train_enabled(train)
signal train_disabled(train)
signal one_left (player)
signal winner(player)
#signal mouse_over_domino(p_domino:Domino)
#signal mouse_left_domino(p_domino:Domino)
#signal mouse_over_domino_area(p_area:DominoArea)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
