class_name BoneYard
extends ColorRect
@onready var domino_container := $VBoxContainer/HFlowContainer

signal domino_clicked(p_domino:DominoControl)
signal domino_right_clicked(p_domino:DominoControl)
var d_scene : PackedScene = preload("res://game_pieces/domino_control.tscn")

func shuffle():
	var d_array = domino_container.get_children()
	d_array.shuffle()
	
	for d in range(0,d_array.size()):
		domino_container.move_child(d_array[d],d)

func add_domino(i:int,j:int,face_up:bool):
	pass
	
func remove_domino(p_domino:DominoControl):
	domino_container.remove_child(p_domino)
	
func populate(p_dots:int,p_face_up:bool):
	var d:DominoControl
	for i:int in range(0,p_dots+1):
		for j:int in range(0,i+1):
			d = d_scene.instantiate()
			d.name = "Domino_"+str(i)+"_"+str(j)
			domino_container.add_child(d)
			d.domino_clicked.connect(_on_domino_clicked)
			d.domino_right_clicked.connect(_on_domino_right_clicked)
			d.set_dots(i,j)
			if p_face_up :
				d.show_dots()
			else :
				d.hide_dots()			
			
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_domino_clicked(p_domino:DominoControl):
	domino_clicked.emit(p_domino)
	
func _on_domino_right_clicked(p_domino:DominoControl):
	domino_right_clicked.emit(p_domino)

# Called every frame. 'delta' is the elapsed time since the previous frame.

func _process(_delta: float) -> void:
	pass
