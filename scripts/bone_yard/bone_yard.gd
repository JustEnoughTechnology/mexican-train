class_name BoneYard
extends ColorRect
# Updated for renamed nodes: boneyard_layout and domino_container

@onready var boneyard_layout : VBoxContainer = $boneyard_layout
@onready var domino_container : HFlowContainer = $boneyard_layout/domino_container
@onready var is_dragging := false
@onready var current_domino : Domino
signal too_many_dominos(dot_count: int)
var d_scene : PackedScene = preload("res://scenes/domino/domino.tscn") #Domino game piece

# --- Configurable max size percentages for BoneYard ---
@export var max_width_percent: float = 0.98 # 98% of window width
@export var max_height_percent: float = 0.6 # 60% of window height

func is_boneyard() -> bool:
	"""Identify this container as a boneyard for drop restriction purposes"""
	return true

## --- HFlowContainer logic merged from h_flow_container.gd ---
func _boneyard_hookup_child_signals() -> void:
	# Ensure all current children are connected for resize/visibility
	for child in domino_container.get_children():
		if child is Control:
			if not child.is_connected("resized", Callable(self, "_on_boneyard_child_resized")):
				child.connect("resized", Callable(self, "_on_boneyard_child_resized"))
			if not child.is_connected("visibility_changed", Callable(self, "_on_boneyard_child_resized")):
				child.connect("visibility_changed", Callable(self, "_on_boneyard_child_resized"))

@warning_ignore("unused_parameter")
func _on_boneyard_child_modified(child: Node) -> void:
	_boneyard_hookup_child_signals()
	call_deferred("update_boneyard_size")

func _on_boneyard_child_resized():
	call_deferred("update_boneyard_size")

func _ready() -> void:
	# Connect signals for child add/remove
	if domino_container.has_signal("child_entered_tree"):
		domino_container.child_entered_tree.connect(_on_boneyard_child_modified)
	if domino_container.has_signal("child_exiting_tree"):
		domino_container.child_exiting_tree.connect(_on_boneyard_child_modified)
	_boneyard_hookup_child_signals()
	#self.size = Vector2($boneyard_layout.size.x,self.size.y)
	call_deferred("update_boneyard_size")

func sort_ascending(d1:Domino, d2:Domino)->bool:
	return d1.get_dots()< d2.get_dots()
	
func sort():
	var d_array =  domino_container.get_children()
	d_array.sort_custom( sort_ascending)
	
func shuffle():
	var d_array = domino_container.get_children()
	d_array.shuffle()
	for d in range(0,d_array.size()):
		domino_container.move_child(d_array[d],d)

func add_domino(i:int,j:int):
	var d = Domino.new(i,j)
	domino_container.add_child(d)
	# Connect right click signal to toggle dots
	d.mouse_right_pressed.connect(_on_domino_right_clicked)
	# Connect domino drop signal if needed
	# d.domino_dropped.connect(_on_domino_dropped)
	_boneyard_hookup_child_signals()
	call_deferred("update_boneyard_size")
	
func remove_domino(p_domino:Domino):
	domino_container.remove_child(p_domino)
	_boneyard_hookup_child_signals()
	call_deferred("update_boneyard_size")
	
func populate(p_dots:int,p_face_up:bool = false):
	var d:Domino
	if p_dots > GameState.MAX_DOTS :
		too_many_dominos.emit(p_dots)
	for i:int in range(0,p_dots+1):
		for j:int in range(0,i+1):
			d = d_scene.instantiate()
			d.name = "Domino_"+str(i)+"_"+str(j)
			domino_container.add_child(d)
			d.set_dots(i,j)
			d.set_face_up(p_face_up)
			# Connect right click signal to toggle dots
			d.mouse_right_pressed.connect(_on_domino_right_clicked)
	_boneyard_hookup_child_signals()
	call_deferred("update_boneyard_size")

# --- Dedicated function to update BoneYard size based on current dominoes ---
func update_boneyard_size():

	await get_tree().process_frame  # Wait for layout update
	var parent_control = get_parent() if get_parent() is Control else null
	var reference_size = parent_control.size if parent_control else get_window().size
	var max_width = round(reference_size.x * max_width_percent)
	var max_height = round(reference_size.y * max_height_percent)

	# Clamp max_width to parent size (never exceed parent, and always round)
	if parent_control:
		max_width = min(max_width, round(parent_control.size.x))

	# Defensive: never allow final_width to exceed max_width
	domino_container.custom_minimum_size.x = max_width
	domino_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Wait for HFlowContainer to update its layout with new min width
	await get_tree().process_frame

	# Remove manual centering; let anchors/scene layout handle horizontal centering


	# --- Enforce anchors and offsets for pixel-perfect centering and clamping ---
	# This ensures the BoneYard node is always centered and never exceeds max_width_percent of its parent
	var anchor_width = max_width
	if self is Control and parent_control:
		self.anchor_left = 0.5
		self.anchor_right = 0.5
		self.offset_left = -anchor_width / 2
		self.offset_right = anchor_width / 2
		self.size_flags_horizontal = 0 # Remove fill/expand

	var vbox = boneyard_layout
	var label_height = vbox.get_child(0).size.y if vbox.get_child_count() > 0 else 0
	var domino_container_height = domino_container.size.y

	# Add label height and padding
	var padded_height = domino_container_height + label_height + 16

	# Clamp to window limits
	var domino_width = 82
	var _min_width = domino_width + 16
	var min_height = domino_container_height + label_height + 16

	# BoneYard width is always max_width (set by parent/container), only height shrinks/grows
	var final_width = max_width
	var final_height = min(max_height, padded_height)
	final_height = max(final_height, min_height)

	# Round to whole pixels
	final_width = round(final_width)
	final_height = round(final_height)

	# Set sizes and size flags for all containers (do not set .size directly)
	final_width = round(final_width)
	final_height = round(final_height)
	self.custom_minimum_size = Vector2(final_width, final_height)
	self.size_flags_horizontal = Control.SIZE_FILL
	vbox.custom_minimum_size = Vector2(final_width, final_height)
	vbox.size_flags_horizontal = Control.SIZE_FILL
	domino_container.custom_minimum_size = Vector2(final_width, 0)
	domino_container.size_flags_horizontal = Control.SIZE_FILL
			
func _unhandled_input(event: InputEvent) -> void:
	gui_input.emit(event)	



# Whenever BoneYard is resized, check for overlap with Hand and adjust if needed
func _on_resized() -> void:
	var parent = get_parent()
	if not parent:
		return
	# Try to find a sibling node named "Hand" (case-insensitive)
	var hand = null
	for child in parent.get_children():
		if typeof(child) == TYPE_OBJECT and child != self and child.has_method("get_name"):
			if child.get_name().to_lower() == "hand":
				hand = child
				break
	if hand and hand is Control:
		# Check for overlap
		var boneyard_rect = self.get_global_rect()
		var hand_rect = hand.get_global_rect()
		if boneyard_rect.intersects(hand_rect):
			# Move Hand down so it does not overlap
			var new_hand_pos = Vector2(hand.position.x, boneyard_rect.end.y + 10)
			hand.position = new_hand_pos

#func _notification(what):
	##match what:
		##40,41,42,60,61,2016,1002,1004: pass
		##_:	
#if GameState.DEBUG_SHOW_WARNINGS:
#    print("notification: ",what," ", Global.get_notification_name(what))
	#
	##if what == NOTIFICATION_PARENTED or what == NOTIFICATION_RESIZED:
		##var parent_control = get_parent() as Control
		##if parent_control:
			##self.size = Vector2(self.size.x,parent_control.size.y)  

@warning_ignore("unused_parameter")
func _on_gui_input(event: InputEvent) -> void:
	pass

## Handler for right-click on a domino
func _on_domino_right_clicked(p_domino: Domino) -> void:
	# Toggle the dots (face up/down) for the clicked domino
	p_domino.toggle_dots()
