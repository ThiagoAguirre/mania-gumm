extends CharacterBody2D
class_name Player

@export var speed: int = 150
@export var jump_velocity: float = -300.0
@export var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
@export var sprite_path: NodePath = ^"AnimatedSprite2D"
@export var animation_player_path: NodePath = ^"AnimationPlayer"
@export var landing_min_fall_distance: float = 64.0

@export_group("Animations")
@export var idle_animation: StringName = &"idle"
@export var run_animation: StringName = &"run"
@export var jump_animation: StringName = &"jump"
@export var fall_animation: StringName = &"jump"
@export var landing_animation: StringName = &"landing"
@export var crouch_idle_animation: StringName = &"crouch_idle"
@export var crouch_walk_animation: StringName = &"crouch_walk"

@onready var player_sprite: Node = get_node_or_null(sprite_path)
@onready var animation_player: AnimationPlayer = get_node_or_null(animation_player_path) as AnimationPlayer

var is_landing: bool = false
var is_tracking_fall: bool = false
var fall_start_y: float = 0.0


func _ready() -> void:
	if animation_player != null:
		animation_player.animation_finished.connect(_on_animation_finished)


func _physics_process(_delta: float) -> void:
	var was_on_floor: bool = is_on_floor()

	if is_landing:
		landing_movement(_delta)
		play_animation(landing_animation)
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

	if player_sprite != null and player_sprite.has_method("animate"):
		var animation_velocity: Vector2 = velocity
		animation_velocity.x = input_direction * speed
		player_sprite.animate(animation_velocity)

	update_animation(velocity, input_direction, is_crouching)


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
	play_animation(landing_animation)


func start_fall_tracking() -> void:
	is_tracking_fall = true
	fall_start_y = position.y


func stop_fall_tracking() -> void:
	is_tracking_fall = false


func should_play_landing() -> bool:
	if not has_animation(landing_animation):
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


func update_animation(current_velocity: Vector2, input_direction: float, is_crouching: bool) -> void:
	if is_landing:
		play_animation(landing_animation)
		return

	if not is_on_floor() and current_velocity.y < 0.0:
		play_animation(jump_animation)
	elif not is_on_floor() and current_velocity.y > 0.0:
		play_animation(fall_animation)
	elif is_crouching:
		update_crouch_animation(input_direction)
	elif input_direction != 0.0:
		play_animation(run_animation)
	else:
		play_animation(idle_animation)


func update_crouch_animation(input_direction: float) -> void:
	if input_direction != 0.0:
		play_animation(crouch_walk_animation)
	else:
		play_animation(crouch_idle_animation)


func play_animation(animation_name: StringName) -> void:
	if animation_player == null:
		return

	var resolved_animation: StringName = resolve_animation_name(animation_name)
	if resolved_animation == StringName():
		resolved_animation = resolve_animation_name(idle_animation)

	if resolved_animation == StringName():
		return

	if animation_player.current_animation != resolved_animation:
		animation_player.play(resolved_animation)


func resolve_animation_name(animation_name: StringName) -> StringName:
	if animation_name == StringName() or animation_player == null:
		return StringName()

	if animation_player.has_animation(animation_name):
		return animation_name

	if animation_name == fall_animation and animation_player.has_animation(jump_animation):
		return jump_animation

	if animation_name == crouch_walk_animation and animation_player.has_animation(crouch_idle_animation):
		return crouch_idle_animation

	return StringName()


func has_animation(animation_name: StringName) -> bool:
	return animation_player != null and animation_player.has_animation(animation_name)


func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == landing_animation:
		is_landing = false
