extends Node2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$BoneYard.set_size(get_window().size)
	$BoneYard.populate(12,false) 
	$BoneYard.shuffle()
# Called every frame. 'delta' is the elapsed time since the previous 

func _process(_delta: float) -> void:
	pass

func raycast_check_for_domino():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = 1
	var result = space_state.intersect_point(parameters)
	print (result)
	
func _on_bone_yard_domino_left_pressed(p_domino: Domino) -> void:
	p_domino.show_dots() # Replace with function body.

func _on_bone_yard_gui_input(event: InputEvent) -> void:
	pass
	

func _on_bone_yard_domino_right_pressed(p_domino: Domino) -> void:
	pass # Replace with function body.
/
