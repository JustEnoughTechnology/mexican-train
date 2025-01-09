class_name DominoNode2D extends Node2D

@export var  domino :Domino = preload("res://data_resources/Domino.tres")
signal show_domino_dots
signal hide_domino_dots
signal domino_clicked(domino:DominoNode2D)
signal toggle_dots


func get_size()->Vector2:
	return $GridContainer.size
	
	
func _show_dots():
	$"GridContainer/0/Label".visible = true
	$"GridContainer/1/Label".visible = true
	
func _hide_dots():
	$"GridContainer/0/Label".visible = false
	$"GridContainer/1/Label".visible = false
		
func set_dots(left:int,right:int):
	domino.dots[0] = left
	domino.dots[1] = right
	
	$"GridContainer/0/Label".text = str(domino.dots[0])
	$"GridContainer/1/Label".text = str(domino.dots[1])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.hide_domino_dots.connect(_hide_dots)	
	self.show_domino_dots.connect(_show_dots)
	
	if domino.dots.is_empty():
		set_dots(0,0)
	else:
		set_dots(domino.dots[0],domino.dots[1])
	_show_dots()
	

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	print("some event")
	if event.is_action("domino_clicked"):
		print("Domino Node clicked")
		self.domino_clicked.emit(self)

func _on_toggle_dots() -> void:
	print("toggling",self.domino.dots)
	$"GridContainer/0/Label".visible = !$"GridContainer/0/Label".visible
	$"GridContainer/1/Label".visible = !$"GridContainer/1/Label".visible


func _on_area_2d_mouse_entered() -> void:
	print("mouse engtered")


func _on_area_2d_mouse_exited() -> void:
	print("mouse left")
	

func _on_gui_input(event: InputEvent) -> void:
	if event.is_action("domino_clicked"):
	domino_clickede
