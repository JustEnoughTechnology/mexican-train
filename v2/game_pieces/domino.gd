class_name Domino extends ColorRect

signal mouse_left_pressed(p_domino: Domino)
signal mouse_right_pressed(p_domino: Domino)
signal mouse_left_released(p_domino: Domino)
signal mouse_right_released(p_domino: Domino)
signal dragged_away (p_domino:Domino)

@onready var d_sprite: DominoSprite = $DominoSprite
@onready var old_modulate := modulate
@onready var is_highlighted := false
@onready var data: DominoData

func flip():
	$CenterContainer.rotation_degrees(180.0)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return false
	
func highlight(on: bool = true):
	modulate = old_modulate if !on else Color(0.9, 0.9, 0.9, 0.75)
	is_highlighted = on

func face_up(p_face_up:bool = true):
	data.is_face_up = p_face_up
	$CenterContainer/DominoFront.visible = true
	
func get_dots() -> Vector2i:
	return d_sprite.get_dots()

func set_dots(p_left: int, p_right: int) -> void:
	d_sprite.set_dots(p_left, p_right)

func show_dots(on: bool = true):
	d_sprite.show_dots(on)
	
func toggle_dots():
	d_sprite.toggle_dots()

func get_domino_size() -> Vector2:
	return d_sprite.get_domino_size()

func _on_domino_sprite_mouse_left_pressed(p_domino: DominoSprite) -> void:
	mouse_left_pressed.emit(self)

func _on_domino_sprite_mouse_entered(p_domino: DominoSprite) -> void:
	mouse_entered.emit(self)

func _on_domino_sprite_mouse_exited(p_domino: DominoSprite) -> void:
	mouse_exited.emit(self)


func _on_domino_sprite_mouse_left_released(p_domino: DominoSprite) -> void:
	mouse_left_released.emit(self)


func _on_domino_sprite_mouse_right_pressed(p_domino: DominoSprite) -> void:
	mouse_right_pressed.emit(self)

func _on_domino_sprite_mouse_right_released(p_domino: DominoSprite) -> void:
	mouse_right_released.emit(self)


func _on_domino_sprite_gui_input(event: InputEvent) -> void:
	emit_signal("gui_input", event)
	 # Replace with function body.
