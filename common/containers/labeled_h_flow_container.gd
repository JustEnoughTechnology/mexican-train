@tool
class_name LabeledHFlowContainer extends ColorRect
@export var label_text : String  :
	set(p_value):
		$VBoxContainer/Label.text = p_value
	get():
		return $VBoxContainer/Label.text
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass
