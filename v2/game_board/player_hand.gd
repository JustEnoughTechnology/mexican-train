class_name PlayerHand extends ColorRect

@onready var domino_container := $HandContainer/bg/DominoContainer
@onready var my_player : Player
@onready var my_label := $HandContainer/bg/Label

var d_scene : PackedScene = preload("res://v2/game_pieces/domino.tscn")
var count:int 

signal domino_dropped(p_domino:Domino)

func get_domino_count() -> int:
	return domino_container.get_child_count()
	
func set_label_text(p_text:String):
	my_label.text = p_text

func get_label_text()->String:
	return my_label.text
	
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
	
func add_domino(p_domino:Domino)->void:
	p_domino.reparent(domino_container)
	
func get_domino(i:int)-> Domino:
	return domino_container.get_child(i)
	
func move_domino(p_domino:Domino,p_dest) ->void:
	p_domino.reparent(p_dest)
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _ready() -> void:
	domino_dropped.connect(add_domino)
	my_label.text = self.name + " Hand"
	
func _process(_delta: float) -> void:
	pass
