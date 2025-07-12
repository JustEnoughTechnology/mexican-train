# Domino2DTest.gd
# Test script for Domino2D: set dots, flip, rotate, drag-and-drop
extends Control

@onready var domino := $VBox/Domino2DInstance
@onready var spin_left := $VBox/Controls/SpinLeft
@onready var spin_right := $VBox/Controls/SpinRight
@onready var btn_set_dots := $VBox/Controls/ButtonSetDots
@onready var btn_flip := $VBox/Controls/ButtonFlip
@onready var btn_orient := $VBox/Controls/ButtonOrient
@onready var drop_target := $DropTarget
@onready var drop_label := $DropTarget/DropLabel

var ORIENTATION_LEFT = 0
var ORIENTATION_TOP = 2
var ORIENTATION_RIGHT = 1
var ORIENTATION_BOTTOM = 3

var orientations = [
	ORIENTATION_LEFT,
	ORIENTATION_TOP,
	ORIENTATION_RIGHT,
	ORIENTATION_BOTTOM
]
var orientation_idx := 0

func _ready():
	# Set initial domino: 6-5, horizontal, 6 on the left
	domino.set_dots(6, 5)
	domino.set_orientation(ORIENTATION_LEFT)
	spin_left.value = 6
	spin_right.value = 5

	btn_set_dots.pressed.connect(_on_set_dots)
	btn_flip.pressed.connect(_on_flip)
	btn_orient.pressed.connect(_on_orient)
	# Set initial dots
	domino.set_dots(spin_left.value, spin_right.value)
	domino.set_orientation(orientations[orientation_idx])
	drop_label.text = "Drop Domino Here"
	# Connect drag-and-drop signals for DropTarget
	drop_target.connect("can_drop_data", Callable(self, "_can_drop_data_on_drop_target"))
	drop_target.connect("drop_data", Callable(self, "_drop_data_on_drop_target"))

func _on_set_dots():
	domino.set_dots(spin_left.value, spin_right.value)

func _on_flip():
	domino.toggle_dots()

func _on_orient():
	orientation_idx = (orientation_idx + 1) % orientations.size()
	domino.set_orientation(orientations[orientation_idx])

# Add drag-and-drop handlers to DropTarget
func _can_drop_data_on_drop_target(_pos, data):
	# Accept Domino2D or Domino (for compatibility)
	return typeof(data) == TYPE_OBJECT and ("get_dots" in data)

func _drop_data_on_drop_target(_pos, data):
	if typeof(data) == TYPE_OBJECT and ("get_dots" in data):
		var dots = data.get_dots()
		drop_label.text = "Dropped: %s-%s" % [dots.x, dots.y]
	else:
		drop_label.text = "Invalid drop"
