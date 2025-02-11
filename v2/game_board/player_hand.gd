class_name PlayerHand extends ColorRect
@onready var domino_container := $VBoxContainer/HFlowContainer
@onready var my_player : Player

var d_scene : PackedScene = preload("res://v2/game_pieces/domino.tscn")
var count:int 

signal domino_clicked(p_domino:Domino)
signal domino_right_clicked(p_domino:Domino)
signal domino_dropped(p_domino:Domino)

func get_domino_count() -> int:
	return domino_container.get_child_count()
	
func set_label_text(p_text:String):
	$VBoxContainer/Label.text = p_text

func get_label_text()->String:
	return $VBoxContainer/Label.text
	
func sort_ascending(domino1:Domino,domino2:Domino)->bool:
	return domino1.get_dots() < domino2.get_dots()

func sort_descending(domino1:Domino,domino2:Domino)->bool:
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

func add_domino(p_domino:Domino)->void:
	p_domino.reparent(domino_container)
	
func get_domino(i:int)-> Domino:
	return $VBoxContainer/HFlowContainer.get_child(i)
	
func move_domino(p_domino:Domino,p_dest) ->void:
	p_domino.reparent(p_dest)
		
func populate(p_dots:int,p_face_up:bool):
	var d:Domino
	for i:int in range(0,p_dots+1):
		for j:int in range(0,i+1):
			d = d_scene.instantiate()
			d.name = "Domino_"+str(i)+"_"+str(j)
			domino_container.add_child(d)
			d.domino_clicked.connect(_on_domino_clicked)
			d.domino_right_clicked.connect(_on_domino_right_clicked)
			d.set_dots(i,j)
			d.show_dots(p_face_up)
			
func _on_domino_clicked(p_domino:Domino):
	domino_clicked.emit(p_domino)
	
func _on_domino_right_clicked(p_domino:Domino):
	domino_right_clicked.emit(p_domino)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _ready() -> void:
	domino_dropped.connect(add_domino)
	
func _process(_delta: float) -> void:
	pass
