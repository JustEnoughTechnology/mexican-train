extends Node2D
var current_domino:Domino
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for d:Domino in $dominos.get_children():
		d.set_dots(randi_range(0,12),randi_range(0,12))
		d.mouse_left_pressed.connect(_on_domino_mouse_left_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_domino_mouse_left_pressed(p_domino: Domino) -> void:
	$PlayerHand.add_domino(p_domino) # Replace with function body.

			
					
