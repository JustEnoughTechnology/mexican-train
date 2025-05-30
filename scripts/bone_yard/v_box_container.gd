extends VBoxContainer
func _ready() -> void:
	if EngineDebugger.is_active():
		push_warning("Vboxcontainer ready:",get_global_rect())
	
#func _notification(what):
	#match what:
		#40,41,42,60,61,2016,1002,1004: pass
		#_:	push_warning("notification: ",what," ", Global.get_notification_name(what))
	#
	#if what == NOTIFICATION_PARENTED or what == NOTIFICATION_RESIZED:
		#var parent_control = get_parent() as Control
		#if parent_control:
			#self.size = Vector2(self.size.x,parent_control.size.y)  


func _on_resized() -> void:
	if EngineDebugger.is_active():
		push_warning("vbox resized ",self.get_global_rect())
	self.get_parent_control().size = Vector2(self.size.x,self.size.y)
	
