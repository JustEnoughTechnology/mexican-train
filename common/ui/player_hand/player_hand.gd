class_name PlayerHand
extends ColorRect
@onready var domino_container := $VBoxContainer/HFlowContainer
signal domino_clicked(p_domino:DominoControl)
signal domino_right_clicked(p_domino:DominoControl)
signal domino_dropped(p_domino:DominoControl)

var d_scene : PackedScene = preload("res://2d/game_pieces/domino_control.tscn")

func sort_ascending(domino1:DominoControl,domino2:DominoControl)->bool:
	return domino1.get_dots() < domino2.get_dots()

func sort_descending(domino1:DominoControl,domino2:DominoControl)->bool:
	return domino1.get_dots() > domino2.get_dots()

func sort(s:GameState.Sort):
	var d_array = domino_container.get_children()
	
	match s:
		GameState.Sort.SORT_ASCENDING:
			d_array.sort_custom(sort_ascending)
		GameState.Sort.SORT_DESCENDING:
			d_array.sort_custom(sort_descending)
		_:
			pass		
	
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
			
func _on_domino_clicked(p_domino:DominoControl):
	domino_clicked.emit(p_domino)
	
func _on_domino_right_clicked(p_domino:DominoControl):
	domino_right_clicked.emit(p_domino)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _ready() -> void:
	domino_dropped.connect(add_domino)
	
func _process(_delta: float) -> void:
	pass
