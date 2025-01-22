extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$DominoSprite.set_dots(3,7)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_domino_sprite_domino_clicked(p_domino: DominoSprite) -> void:
	p_domino.set_dots(randi_range(0,12),randi_range(0,12))

func _on_domino_sprite_domino_right_clicked(p_domino: DominoSprite) -> void:
	p_domino.flip()
