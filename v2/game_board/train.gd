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
	domino_container.columns = domino_container.get_child_count()+1
	p_domino.reparent(domino_container)
	p_domino.set_face_up()
	
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
