extends Node2D

@onready var is_dragging:=false
@onready var current_domino:Domino 

func _ready() -> void:
	$BoneYard.set_size(get_window().size)
	$BoneYard.populate(12,false) 
	$BoneYard.shuffle()
# Called every frame. 'delta' is the elapsed time since the previous 

func _process(_delta: float) -> void:
	pass
	
func _on_bone_yard_domino_left_pressed(p_domino: Domino) -> void:
	p_domino.show_dots() # Replace with function body.

func _on_bone_yard_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and is_dragging:
		current_domino.position += event.relative
	
func _on_bone_yard_domino_right_pressed(p_domino: Domino) -> void:
	p_domino.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_dragging = true
	current_domino = p_domino
	p_domino.highlight(true)

func _on_bone_yard_domino_right_released(p_domino: Domino) -> void:
	is_dragging = false
	current_domino = null
	p_domino.mouse_filter = Control.MOUSE_FILTER_PASS
	p_domino.highlight(false)
