extends Node2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$BoneYard.set_size(get_window().size)
	$BoneYard.populate(12,true) 
	$BoneYard.shuffle()
# Called every frame. 'delta' is the elapsed time since the previous 
func _input(event):
	if event.is_action_pressed("domino_selected"):
		raycast_check_for_domino()

func _process(delta: float) -> void:
	pass

func raycast_check_for_domino():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = 1
	var result = space_state.intersect_point(parameters)
	print (result)
