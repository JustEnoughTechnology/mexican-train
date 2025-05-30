extends EditorPlugin

var browser_panel

func _enter_tree():
	browser_panel = preload("res://assets/addons/class_d_b_browser/class_d_b_browser.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, browser_panel)
	add_tool_menu_item("ClassDB Browser", Callable(self, "_on_menu_item_pressed"))

func _exit_tree():
	remove_control_from_docks(browser_panel)
	remove_tool_menu_item("ClassDB Browser")

func _on_menu_item_pressed():
	browser_panel.visible = not browser_panel.visible
