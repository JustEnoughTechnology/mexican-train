extends TextureRect
class_name ExperimentalDomino

## Experimental domino implementation using shaders for dot coloring
## This version pre-loads SVG assets and uses shaders for dynamic coloring

@export var left_dots: int = 0 : set = set_left_dots
@export var right_dots: int = 0 : set = set_right_dots
@export var orientation: String = "top" : set = set_orientation

var base_texture_path: String = "res://assets/experimental/dominos_white/"
var current_domino_key: String = ""

func _ready():
    update_domino_display()

func set_left_dots(value: int):
    left_dots = clamp(value, 0, 18)
    update_shader_parameters()

func set_right_dots(value: int):
    right_dots = clamp(value, 0, 18)
    update_shader_parameters()

func set_orientation(value: String):
    if value in ["top", "bottom", "left", "right"]:
        orientation = value
        update_domino_display()

func update_shader_parameters():
    if material and material is ShaderMaterial:
        var shader_material = material as ShaderMaterial
        shader_material.set_shader_parameter("left_dots", left_dots)
        shader_material.set_shader_parameter("right_dots", right_dots)
        shader_material.set_shader_parameter("is_vertical", orientation in ["top", "bottom"])

func update_domino_display():
    var domino_key = "%d-%d" % [left_dots, right_dots]
    if domino_key == current_domino_key and texture != null:
        return # No change needed
    
    current_domino_key = domino_key
    
    # Load the appropriate white-dot SVG
    var texture_path = base_texture_path + "white_domino-%s_%s.svg" % [domino_key, orientation]
    
    if ResourceLoader.exists(texture_path):
        texture = load(texture_path)
        update_shader_parameters()
    else:
        push_error("Could not find texture: " + texture_path)

func configure_domino(left: int, right: int, orient: String = "top"):
    """Configure the domino with specific dot counts and orientation."""
    left_dots = left
    right_dots = right
    orientation = orient
    update_domino_display()

func get_domino_data() -> Dictionary:
    """Get current domino configuration as data."""
    return {
        "left_dots": left_dots,
        "right_dots": right_dots,
        "orientation": orientation,
        "texture_path": base_texture_path + "white_domino-%s_%s.svg" % [current_domino_key, orientation]
    }
