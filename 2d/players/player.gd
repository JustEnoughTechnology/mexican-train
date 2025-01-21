class_name Player extends CharacterBody2D

@onready var player_name = $AnimatedSprite2D/PlayerName
func _ready() -> void:
	player_name.text = self.name
	 
func _on_renamed() -> void:
	player_name.text = name  # Replace with function body.
