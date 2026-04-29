extends CharacterBody2D
class_name Player

@export var speed: int = 150
@export var jump_velocity: float = -300.0
@export var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
@export var sprite_path: NodePath = ^"AnimatedSprite2D"
@export var landing_min_fall_distance: float = 64.0

@onready var player_animations: PlayerAnimations = get_node_or_null(sprite_path) as PlayerAnimations

var is_landing: bool = false
var is_tracking_fall: bool = false
var fall_start_y: float = 0.0


func _ready() -> void:
	if player_animations != null:
		player_animations.landing_finished.connect(_on_landing_finished)


func _physics_process(_delta: float) -> void:
	var was_on_floor: bool = is_on_floor()

	if is_landing:
		landing_movement(_delta)
		if player_animations != null:
			player_animations.play_landing()
		return

	var is_crouching: bool = is_crouch_pressed()
	var input_direction: float = get_horizontal_input()

	horizontal_movement_env(input_direction)

	if not is_on_floor():
		velocity.y += gravity * _delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()

	if was_on_floor and not is_on_floor():
		start_fall_tracking()

	var just_landed: bool = not was_on_floor and is_on_floor()
	if just_landed and should_play_landing():
		stop_fall_tracking()
		start_landing()
		return
	elif just_landed:
		stop_fall_tracking()

	if player_animations != null:
		var animation_velocity: Vector2 = velocity
		animation_velocity.x = input_direction * speed
		player_animations.animate(animation_velocity, velocity, input_direction, is_crouching, is_on_floor())


func horizontal_movement_env(input_direction: float) -> void:
	velocity.x = input_direction * speed


func landing_movement(delta: float) -> void:
	velocity.x = 0.0

	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()


func start_landing() -> void:
	is_landing = true
	velocity.x = 0.0
	if player_animations != null:
		player_animations.play_landing()


func start_fall_tracking() -> void:
	is_tracking_fall = true
	fall_start_y = position.y


func stop_fall_tracking() -> void:
	is_tracking_fall = false


func should_play_landing() -> bool:
	if player_animations == null or not player_animations.has_landing_animation():
		return false

	if not is_tracking_fall:
		return false

	return position.y - fall_start_y >= landing_min_fall_distance


func get_horizontal_input() -> float:
	return Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")


func is_crouch_pressed() -> bool:
	if InputMap.has_action("crouch") and Input.is_action_pressed("crouch"):
		return true

	return Input.is_key_pressed(KEY_CTRL)


func _on_landing_finished() -> void:
	is_landing = false
