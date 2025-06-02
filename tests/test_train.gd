extends Control
var d_scene : PackedScene = preload("res://scenes/domino/domino.tscn") 
var d:Domino
# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	pass
	
func _ready() -> void:
	get_window().title = get_name()
	for i in range(35):
		d = d_scene.instantiate()
		$dominos.add_child(d)
		d.set_dots(randi_range(0,12),randi_range(0,12))
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass
