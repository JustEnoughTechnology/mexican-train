extends Control
var d_scene : PackedScene = preload("res://game_pieces/domino.tscn") 
var d:Domino
# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	pass
	
func _ready() -> void:
	for i in range(35):
		d = d_scene.instantiate()
		$dominos.add_child(d)
		d.set_dots(randi_range(0,12),randi_range(0,12))
		d.mouse_left_pressed.connect(_on_domino_mouse_left_pressed)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_domino_mouse_left_pressed(p_domino: Domino) -> void:
	$Train.add_domino(p_domino) # Replace with function body.
	p_domino.mouse_left_pressed.disconnect(_on_domino_mouse_left_pressed)
