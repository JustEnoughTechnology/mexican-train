extends Node2D
@onready var is_dragging:=false
@onready var current_domino:Domino 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_window().title = get_name()
	
	$Domino1.set_dots(5,6) 
	$Domino2.set_dots(8,9) 
	$Domino1.set_face_up()
	$Domino2.set_face_up()
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass
	
func _on_mouse_left_pressed(p_domino: Domino) -> void:
	p_domino.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_dragging = true
	current_domino = p_domino
	p_domino.highlight(true)

func _on_mouse_left_released(p_domino: Domino) -> void:
	is_dragging = false
	current_domino = null
	p_domino.mouse_filter = Control.MOUSE_FILTER_PASS
	p_domino.highlight(false)
	
#func _on_gui_input(event: InputEvent) -> void:
	#if event is InputEventMouseMotion and is_dragging:
		#current_domino.position += event.relative
		#
func _on_mouse_right_pressed(p_domino: Domino) -> void:
	if p_domino.has_method("set_orientation"):
		p_domino.set_orientation(p_domino.ORIENTATION_LARGEST_TOP)
		p_domino.get_child(-1).text = str(p_domino.rotation_degrees)
	else:
		p_domino.get_child(-1).text = "no set_orientation()" 
			
