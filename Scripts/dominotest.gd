extends Node
var dominoes :Array[DominoNode2D]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var domino:PackedScene = load("res://Scenes/domino_control.tscn")
	var domino_node:DominoNode2D = DominoNode2D.new()
	var domino_control:DominoControl = DominoControl.new()
	for i in range(13):
		breakpoint
		for j in range(i+1):
			domino_control = domino.instantiate()
			domino_control.name = "Domino "+str(i)+"-"+str(j)
			domino_node = domino_control.node2d
			domino_node.set_dots(i,j)
			dominoes.append( domino_control)

	dominoes.shuffle()
	$DominoBag.visible = true
	$DominoGrid.visible = true
	for i in range(13):
		breakpoint
		for j in range (i+1):	
			domino_control = dominoes.pop_back()
			$DominoGrid.add_child(domino_control,true)
			domino_node = domino_control.node2d.duplicate()
			domino_node.translate(Vector2(i*82,j*45))
			$DominoBag.add_child(domino_node,true)
			dominoes.push_front(domino_control)
	$DominoBag.visible = false		
			
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass
