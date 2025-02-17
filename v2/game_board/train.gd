class_name Train extends ColorRect

@onready var train_container := $TrainContainer
@onready var domino_container := $TrainContainer/bg/DominoContainer
@export var train_color:Color:
	get: 
		return $TrainContainer/bg.color
	set(val):
		$TrainContainer/bg.color = val
		

@export var label_text : String  :
	set(p_value):
		$TrainContainer/bg/Label.text = p_value
	get():
		return $TrainContainer/bg/Label.text
		
func add_domino(p_domino:Domino)->void:
	var d_size : Vector2 = train_container.size
	
	domino_container.columns = domino_container.get_child_count()+1
	train_container.set_size(d_size+Vector2(p_domino.size.x,0))
	p_domino.reparent(domino_container)
	p_domino.set_face_up()
	

func _on_domino_container_resized() -> void:
	print($".".get_rect())
	pass #$TrainContainer.reset_size()
