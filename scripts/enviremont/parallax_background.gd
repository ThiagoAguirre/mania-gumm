extends ParallaxBackground

class_name Background

# Godot 4:
# - export(bool) -> @export var nome: bool
# - export(Array, int) -> @export var nome: Array[int]

@export var can_process: bool = true
@export var layer_speed: Array[float] = []

func _ready() -> void:
	set_physics_process(can_process)

func _physics_process(delta: float) -> void:
	for index in range(get_child_count()):
		var child: Node = get_child(index)
		var layer := child as ParallaxLayer
		if layer:
			var speed: float = layer_speed[index] if index < layer_speed.size() else 0.0
			layer.motion_offset.x -= speed * delta
