class_name DominoNode2D extends Node2D
signal Domino_Node_Initialized()
var _dots :Dictionary ={}
var handle_notification : Callable = Callable(self,"link_parent" )
		
func set_dots(left:int,right:int):
	print("setting dots:%d - %d"%[left,right])
	_dots["0"] = left
	_dots["1"] = right
	$"0/Label".text = str(_dots["0"])
	$"1/Label".text = str(_dots["1"])
	
func _enter_tree() -> void:
	print ("node2d entering tree")

func link_parent(what:int):
	var p :DominoControl
	match what:
		NOTIFICATION_PARENTED:
			
			print("parented")
			print( self.get_parent().get_class())
			print(self.get_parent().name)
			if self.get_parent().name == "DominoControl" :
				p = self.get_parent()
				p.node2d = self	
				handle_notification = do_nothing

func do_nothing(_what:int):
	pass
	
func _notification(what: int) -> void:
	handle_notification.call(what)
	
				
func _init() ->void:
	
	print ("initializing node")		
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print ("node ready")
	if !_dots.has("0"):
		set_dots(0,0)
	print(_dots)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
