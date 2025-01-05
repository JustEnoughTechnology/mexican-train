class_name DominoControl extends Control
signal Domino_Control_Initialized(signal_name:String)

const DOMINO_NODE = preload("res://Scenes/domino_Node2D.tscn")
var node2d: DominoNode2D
func _init ():
	print("initializing control")	

func _ready() -> void:
	print("control ready")
