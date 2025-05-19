class_name DominoGameContainer extends ColorRect

@onready var my_player : Player
@onready var top_container :HBoxContainer = $TopContainer
@onready var domino_container : GridContainer= $TopContainer/bg/DominoContainer
@onready var my_label :Label =$TopContainer/bg/Label

@export var bg_color:Color:
	get: 
		return $TopContainer/bg.color
	set(val):
		$TopContainer/bg.color = val
		
<<<<<<<< HEAD:scripts/game_board/domino_game_container.gd
var d_scene : PackedScene = preload("uid://htfoo57txyc1") # Domino.tscn
========
var d_scene : PackedScene = preload("res://game_pieces/domino.tscn")
>>>>>>>> 8997d63e58dfdd559b24b196f66b00a42b1399ee:scenes/game_board/domino_game_container.gd

@export var label_text : String  :
	set(p_value):
		$TopContainer/bg/Label.text = p_value
	get():
		return $TopContainer/bg/Label.text

func get_domino_count() -> int:
	return domino_container.get_child_count()
	
func set_label_text(p_text:String):
	self.my_label.text = p_text

func get_label_text()->String:
	return self.my_label.text
	
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
	
func add_domino(p_domino:Domino,p_face_up:bool=true)->void:
	var d_size : Vector2 = top_container.size
	
	domino_container.columns = domino_container.get_child_count()+1
	top_container.set_size(d_size+Vector2(p_domino.size.x+get_theme_constant("h_separation","GridContainer"),0))
	p_domino.reparent(domino_container)
	p_domino.set_face_up(p_face_up)
	print(d_size,p_domino.get_rect(), p_domino.get_global_rect())

func get_domino(i:int)-> Domino:
	return domino_container.get_child(i)
	
func move_domino(p_domino:Domino,p_dest) ->void:
	p_domino.reparent(p_dest)
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _ready() -> void:
	set_label_text( self.name )
	self.color.a = 0			
