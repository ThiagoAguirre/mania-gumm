extends CharacterBody2D
class_name Player

@export var speed: int = 150
@export var jump_velocity: float = -300.0
@export var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
@export var sprite_path: NodePath = ^"AnimatedSprite2D"

@onready var player_sprite: AnimatedSprite2D = get_node_or_null(sprite_path) as AnimatedSprite2D


func _physics_process(_delta: float) -> void:
	# Landing temporariamente desativado.
	# var was_on_floor: bool = is_on_floor()
	var is_crouching: bool = is_crouch_pressed()

	horizontal_movement_env()

	if not is_on_floor():
		velocity.y += gravity * _delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()

	# Landing temporariamente desativado.
	# var just_landed: bool = not was_on_floor and is_on_floor()
	# if just_landed:
	# 	velocity.x = 0.0

	if player_sprite != null and player_sprite.has_method("animate"):
		player_sprite.animate(velocity, is_on_floor(), false, is_crouching)


func horizontal_movement_env() -> void:
	var input_direction: float = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = input_direction * speed


func is_crouch_pressed() -> bool:
	if InputMap.has_action("crouch") and Input.is_action_pressed("crouch"):
		return true

	return Input.is_key_pressed(KEY_CTRL)
