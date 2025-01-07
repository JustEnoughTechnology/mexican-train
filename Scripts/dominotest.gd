extends Node
var dominoes :Array[Control]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var a_domino:PackedScene = load( "res://Scenes/domino_Node2D.tscn")
	var domino_node:DominoNode2D #= DominoNode2D.new()
	var control_node:Control
	for i in range(13):
		
		for j in range(i+1):
			control_node = Control.new()
			control_node.name = "Domino "+str(i)+"-"+str(j)
			domino_node = a_domino.instantiate()
			domino_node.name = "Domino"
			domino_node.set_dots(i,j)
			control_node.add_child(domino_node)
			dominoes.append( control_node)
			$VBoxContainer/Boneyard/Dominos.add_child(control_node)
	
	#dominoes.shuffle()
	
	#for i in range(13):
		#
		#for j in range (i+1):	
			#domino_control = dominoes.pop_back()
			#$DominoGrid.add_child(domino_control,true)
			#domino_node = domino_control.duplicate().node2d
			#domino_node.reparent($DominoBag)
			#domino_node.name = domino_control.name
			#domino_node.translate(Vector2(i*82,j*45))
			#$DominoBag.add_child(domino_node,true)
			#dominoes.push_front(domino_control)
	#$DominoBag.visible = false		
			
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass
