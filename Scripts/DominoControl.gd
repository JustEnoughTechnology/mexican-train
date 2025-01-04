class_name DominoControl extends Control

const DOMINO_NODE = preload("res://Scenes/domino_Node2D.tscn")
var node2d: DominoNode2D
func _init ():
	$".".add_child( DOMINO_NODE.instantiate())
	node2d = $DominoNode2D.get_node(".")
