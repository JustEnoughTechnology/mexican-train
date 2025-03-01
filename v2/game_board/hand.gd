class_name Hand extends DominoGameContainer
signal domino_count_changed

@onready var score:int = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _ready() -> void:
	super._ready()
		

func _on_domino_container_child_order_changed() -> void:
	score = 0
	for d:Domino in domino_container.get_children():
		score += d.get_dots().x+ d.get_dots().y
	domino_count_changed.emit()

		
	
