extends Panel

@onready var drop_label := $DropLabel

func _can_drop_data(_pos, data):
	# Accept Domino2D or Domino (for compatibility)
	return typeof(data) == TYPE_OBJECT and ("get_dots" in data)

func _drop_data(_pos, data):
	if typeof(data) == TYPE_OBJECT and ("get_dots" in data):
		var dots = data.get_dots()
		drop_label.text = "Dropped: %s-%s" % [dots.x, dots.y]
	else:
		drop_label.text = "Invalid drop"
