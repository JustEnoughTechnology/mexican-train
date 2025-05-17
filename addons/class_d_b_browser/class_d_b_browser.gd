extends VBoxContainer

@onready var search_box = $SearchBox
@onready var class_list = $ClassList
@onready var class_info = $Scroll/ClassInfo
@onready var export_button = $ExportButton
@onready var jump_button = $JumpToParentButton

func _ready():
	_populate_class_list()

func _populate_class_list():
	class_list.clear()
	for the_class_name in ClassDB.get_class_list():
		class_list.add_item(the_class_name)
	class_list.sort_items_by_text()

func _on_SearchBox_text_changed(new_text):
	for i in range(class_list.item_count):
		var item_text = class_list.get_item_text(i).to_lower()
		class_list.set_item_hidden(i, not item_text.contains(new_text.to_lower()))

func _on_ClassList_item_selected(index):
	var the_class_name = class_list.get_item_text(index)
	_display_class_info(the_class_name)

func _display_class_info(the_class_name: String):
	var parent = ClassDB.get_parent_class(the_class_name)
	var info = "🔹 Class: %s\n🔸 Inherits: %s" % [the_class_name, parent]

	info += _build_section("🛠️ Methods", ClassDB.class_get_method_list(the_class_name), "name", "()", true)
	info += _build_section("📦 Properties", ClassDB.class_get_property_list(the_class_name), "name", "", true)
	info += _build_section("📡 Signals", ClassDB.class_get_signal_list(the_class_name), "name", "", true)
	info += _build_constants_section(the_class_name)

	class_info.text = info
	jump_button.disabled = (parent == "" or not ClassDB.class_exists(parent))

func _build_section(title: String, items: Array, key: String, suffix: String, show: bool) -> String:
	if items.is_empty():
		return ""
	var result = "\n\n%s:" % title
	for item in items:
		if item.has(key):
			result += "\n  - %s%s" % [item[key], suffix]
	return result

func _build_constants_section(the_class_name: String) -> String:
	var constants = ClassDB.class_get_integer_constant_list(the_class_name)
	if constants.is_empty():
		return ""
	var result = "\n\n📐 Constants:"
	for constant in constants:
		var value = ClassDB.class_get_integer_constant(the_class_name, constant)
		result += "\n  - %s = %d" % [constant, value]
	return result

func _on_ExportButton_pressed():
	var index = class_list.get_selected_items()[0]
	var the_class_name = class_list.get_item_text(index)
	var file = FileAccess.open("user://%s_metadata.txt" % the_class_name, FileAccess.WRITE)
	file.store_string(class_info.text)
	file.close()
	print("Exported metadata for", the_class_name)

func _on_JumpToParentButton_pressed():
	var index = class_list.get_selected_items()[0]
	var the_class_name = class_list.get_item_text(index)
	var parent = ClassDB.get_parent_class(the_class_name)
	if parent != "":
		for i in range(class_list.item_count):
			if class_list.get_item_text(i) == parent:
				class_list.select(i)
				_display_class_info(parent)
				break
