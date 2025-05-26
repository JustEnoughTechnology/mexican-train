extends VBoxContainer
func _notification(what):
	push_warning("notification: ",what," ", Global.get_notification_name(what))
	
	if what == NOTIFICATION_PARENTED or what == NOTIFICATION_RESIZED:
		var parent_control = get_parent() as Control
		if parent_control:
			self.size = Vector2(self.size.x,parent_control.size.y)  
