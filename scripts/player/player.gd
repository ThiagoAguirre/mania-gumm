extends CharacterBody2D
class_name Player

@onready var player_sprite: PlayerTexture = $Texture

@export var speed: int = 150
@export var jump_velocity: float = -300.0
@export var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))


func _physics_process(_delta: float) -> void:
	var was_on_floor: bool = is_on_floor()

	horizontal_movement_env()

	if not is_on_floor():
		velocity.y += gravity * _delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()

	var just_landed: bool = not was_on_floor and is_on_floor()
	player_sprite.animate(velocity, is_on_floor(), just_landed)


func horizontal_movement_env() -> void:
	var input_direction: float = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = input_direction * speed
