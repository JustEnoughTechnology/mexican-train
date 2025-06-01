# test_boneyard_basic.gd
# Standalone test for BoneYard drag-and-drop and basic interaction
extends Control

@onready var boneyard = $BoneYard
@onready var status_label = $StatusLabel

func _ready():
	status_label.text = "Drag a domino from the boneyard. Right-click to flip."
	boneyard.populate(6, false)
	# Connect right-click signal for all dominoes
	for d in boneyard.get_node("VBoxContainer/HFlowContainer").get_children():
		if d.has_signal("mouse_right_pressed"):
			d.mouse_right_pressed.connect(_on_domino_right_pressed)

func _on_domino_right_pressed(domino):
	status_label.text = "Right-clicked: " + str(domino.get_dots())
