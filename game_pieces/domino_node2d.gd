class_name DominoNode2D extends Node2D

@export var  domino :Domino = preload("res://data_resources/domino.tres")
signal show_domino_dots
signal hide_domino_dots
signal domino_clicked(domino:DominoNode2D)
signal toggle_dots

var is_visible :bool = true

func get_size()->Vector2:
	return $Area2D/CollisionShape2D/GridContainer.size
		
func _show_dots():
	
	$"Area2D/CollisionShape2D/GridContainer/0".set_texture( load("res://tiles/domino_dots_%d.tres"%domino.dots[0]))
	$"Area2D/CollisionShape2D/GridContainer/1".set_texture( load("res://tiles/domino_dots_%d.tres"%domino.dots[1]))
	is_visible = true

func _hide_dots():
	$"Area2D/CollisionShape2D/GridContainer/0/Label".set_texture(load("res://tiles/domino_dots_0.tres"))
	$"Area2D/CollisionShape2D/GridContainer/1/Label".set_texture(load("res://tiles/domino_dots_0.tres"))
	is_visible = false
		
func set_dots(left:int,right:int):
	domino.dots[0] = left
	domino.dots[1] = right
	_show_dots()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.hide_domino_dots.connect(_hide_dots)	
	self.show_domino_dots.connect(_show_dots)
	
	if domino.dots.is_empty():
		self.set_dots(0,0)
	else:
		self.set_dots(domino.dots[0],domino.dots[1])
	self._show_dots()
	
	
func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	print("some event")
	if event.is_action("domino_clicked"):

		print("Domino Node clicked")
		self.domino_clicked.emit(self)

func _on_toggle_dots() -> void:
	print("toggling",self.domino.dots)
	if is_visible:
		_show_dots()
	else:
		_hide_dots()


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed( "domino_clicked"):
		print("captured click on gui input")
		domino_clicked.emit(self)
