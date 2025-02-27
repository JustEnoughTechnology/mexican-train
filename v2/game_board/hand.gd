class_name Hand extends DominoGameContainer
signal domino_count_changed

@onready var score:int = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _ready() -> void:
	super._ready()
		


func _on_domino_container_child_order_changed() -> void:
	for d in domino_container.get_children():
		
	
