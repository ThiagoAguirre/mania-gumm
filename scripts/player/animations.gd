extends AnimatedSprite2D
class_name PlayerAnimatedSprite


func _ready() -> void:
	stop()


func animate(current_velocity: Vector2) -> void:
	verify_position(current_velocity)


func verify_position(current_velocity: Vector2) -> void:
	if current_velocity.x > 0.0:
		flip_h = false
	elif current_velocity.x < 0.0:
		flip_h = true
