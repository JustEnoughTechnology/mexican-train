extends Control
var current_domino:Domino


var d_scene : PackedScene = preload("res://scenes/domino/domino.tscn") 
var d:Domino
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(35):
		d = d_scene.instantiate()
		$dominos.add_child(d)
		d.set_dots(randi_range(0,12),randi_range(0,12))
		d.mouse_left_pressed.connect(_on_domino_mouse_left_pressed)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass

func _on_domino_mouse_left_pressed(p_domino: Domino) -> void:
	$Hand.add_domino(p_domino) # Replace with function body.
	p_domino.mouse_left_pressed.disconnect(_on_domino_mouse_left_pressed)

			
					
