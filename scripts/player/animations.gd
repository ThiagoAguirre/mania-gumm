extends AnimatedSprite2D
class_name PlayerAnimations

signal landing_finished
signal attack_finished

@export var animation_player_path: NodePath = ^"../AnimationPlayer"

@export_group("Animations")
@export var idle_animation: StringName = &"idle"
@export var run_animation: StringName = &"run"
@export var jump_animation: StringName = &"jump"
@export var fall_animation: StringName = &"jump"
@export var landing_animation: StringName = &"landing"
@export var crouch_idle_animation: StringName = &"crouch_idle"
@export var crouch_walk_animation: StringName = &"crouch_walk"
@export var punch_animation: StringName = &"punch"

@onready var animation_player: AnimationPlayer = get_node_or_null(animation_player_path) as AnimationPlayer

var is_attacking: bool = false


func _ready() -> void:
	stop()
	if animation_player != null:
		animation_player.animation_finished.connect(_on_animation_finished)


func animate(facing_velocity: Vector2, current_velocity: Vector2, input_direction: float, is_crouching: bool, on_floor: bool) -> void:
	verify_position(facing_velocity)
	update_animation(current_velocity, input_direction, is_crouching, on_floor)


func verify_position(current_velocity: Vector2) -> void:
	if current_velocity.x > 0.0:
		flip_h = false
	elif current_velocity.x < 0.0:
		flip_h = true


func play_landing() -> void:
	is_attacking = false
	play_animation(landing_animation)


func play_attack() -> bool:
	if is_attacking:
		return false

	if not has_animation(punch_animation):
		return false

	is_attacking = true
	play_animation(punch_animation, true)
	_finish_attack_after_animation()
	return true


func update_animation(current_velocity: Vector2, input_direction: float, is_crouching: bool, on_floor: bool) -> void:
	if should_keep_attack_animation(input_direction, is_crouching, on_floor):
		return

	if not on_floor and current_velocity.y < 0.0:
		play_animation(jump_animation)
	elif not on_floor and current_velocity.y > 0.0:
		play_animation(fall_animation)
	elif is_crouching:
		update_crouch_animation(input_direction)
	elif input_direction != 0.0:
		play_animation(run_animation)
	else:
		play_animation(idle_animation)


func should_keep_attack_animation(input_direction: float, is_crouching: bool, on_floor: bool) -> bool:
	return is_attacking and on_floor and input_direction == 0.0 and not is_crouching


func update_crouch_animation(input_direction: float) -> void:
	if input_direction != 0.0:
		play_animation(crouch_walk_animation)
	else:
		play_animation(crouch_idle_animation)


func play_animation(animation_name: StringName, restart: bool = false) -> void:
	if animation_player == null:
		return

	var resolved_animation: StringName = resolve_animation_name(animation_name)
	if resolved_animation == StringName():
		resolved_animation = resolve_animation_name(idle_animation)

	if resolved_animation == StringName():
		return

	if restart:
		animation_player.stop()

	if restart or animation_player.current_animation != resolved_animation:
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


func has_landing_animation() -> bool:
	return has_animation(landing_animation)


func _finish_attack_after_animation() -> void:
	var attack_duration: float = 0.0
	var resolved_animation: StringName = resolve_animation_name(punch_animation)
	if resolved_animation != StringName() and animation_player != null:
		attack_duration = animation_player.get_animation(resolved_animation).length

	if attack_duration <= 0.0:
		_finish_attack()
		return

	await get_tree().create_timer(attack_duration).timeout
	_finish_attack()


func _finish_attack() -> void:
	if not is_attacking:
		return

	is_attacking = false
	attack_finished.emit()


func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == landing_animation:
		landing_finished.emit()
	elif animation_name == punch_animation:
		_finish_attack()
