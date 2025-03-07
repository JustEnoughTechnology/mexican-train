class_name BoneYard
extends ColorRect

@onready var domino_container := $VBoxContainer/HFlowContainer
@onready var is_dragging:=false
@onready var current_domino:Domino 

signal domino_left_pressed(p_domino:Domino)
signal domino_right_pressed(p_domino:Domino)
signal domino_left_released(p_domino:Domino)
signal domino_right_released(p_domino:Domino)

var d_scene : PackedScene = preload("res://v2/game_pieces/domino.tscn") #Domino game piece

func sort_ascending(d1:Domino, d2:Domino)->bool:
	return d1.get_dots()< d2.get_dots()
	
func sort():
	var d_array =  domino_container.get_children()
	d_array.sort_custom( sort_ascending)
	
func shuffle():
	var d_array = domino_container.get_children()
	d_array.shuffle()
	
	for d in range(0,d_array.size()):
		domino_container.move_child(d_array[d],d)

func add_domino(i:int,j:int,face_up:bool):
	domino_container.add_child(Domino.new(i,j))
	
func remove_domino(p_domino:Domino):
	domino_container.remove_child(p_domino)
	
func populate(p_dots:int,p_face_up:bool):
	var d:Domino
	for i:int in range(0,p_dots+1):
		for j:int in range(0,i+1):
			d = d_scene.instantiate()
			d.name = "Domino_"+str(i)+"_"+str(j)
			domino_container.add_child(d)
			d.connect("mouse_left_pressed",_on_domino_left_pressed)
			d.connect("mouse_right_pressed",_on_domino_right_pressed)
			d.connect("mouse_right_released",_on_domino_right_released)
			d.connect("mouse_left_released",_on_domino_left_released)
			d.set_dots(i,j)
			d.set_face_up(p_face_up)		
			
func _on_domino_left_pressed(p_domino:Domino):
	domino_left_pressed.emit(p_domino)
func _on_domino_right_pressed(p_domino:Domino):
	domino_right_pressed.emit(p_domino)
func _on_domino_left_released(p_domino:Domino):
	domino_left_released.emit(p_domino)
func _on_domino_right_released(p_domino:Domino):
	domino_right_released.emit(p_domino)
func _unhandled_input(event: InputEvent) -> void:
	gui_input.emit(event)	
