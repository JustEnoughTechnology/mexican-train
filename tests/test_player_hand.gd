extends Control
var current_domino:Domino
<<<<<<<< HEAD:tests/player_hand/test_player_hand.gd
var d_scene : PackedScene = preload("uid://htfoo57txyc1") #domino scene
========
var d_scene : PackedScene = preload("res://game_pieces/domino.tscn") 
>>>>>>>> 8997d63e58dfdd559b24b196f66b00a42b1399ee:tests/test_player_hand.gd
var d:Domino
# Called when the node enters the scene tree for the first time.
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
	$Hand.add_domino(p_domino) # Replace with function body.
	p_domino.mouse_left_pressed.disconnect(_on_domino_mouse_left_pressed)

			
					
