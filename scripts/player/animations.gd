extends AnimatedSprite2D
class_name PlayerAnimations

signal landing_finished
signal attack_finished
signal wall_land_finished(side: int)

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
@export var wall_land_left_animation: StringName = &"wall_land_left"
@export var wall_land_right_animation: StringName = &"wall_land_right"
@export var wall_slide_left_animation: StringName = &"wall_slide_left"
@export var wall_slide_right_animation: StringName = &"wall_slide_right"

@onready var animation_player: AnimationPlayer = get_node_or_null(animation_player_path) as AnimationPlayer

var is_attacking: bool = false
var is_wall_landing: bool = false
var is_wall_sliding: bool = false
var current_wall_side: int = 0


func _ready() -> void:
	stop()
	if animation_player != null:
		animation_player.animation_finished.connect(_on_animation_finished)
		configure_wall_animation_loops()


func animate(facing_velocity: Vector2, current_velocity: Vector2, input_direction: float, is_crouching: bool, on_floor: bool) -> void:
	if is_wall_landing or is_wall_sliding:
		return

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


func play_wall_land(side: int) -> bool:
	var animation_name: StringName = get_wall_land_animation(side)
	if animation_name == StringName():
		return false

	is_attacking = false
	is_wall_landing = true
	is_wall_sliding = false
	current_wall_side = side
	reset_wall_flip()
	play_animation(animation_name, true)
	return true


func play_wall_slide(side: int) -> bool:
	var animation_name: StringName = get_wall_slide_animation(side)
	if animation_name == StringName():
		return false

	is_wall_landing = false
	is_wall_sliding = true
	current_wall_side = side
	reset_wall_flip()
	play_animation(animation_name)
	return true


func stop_wall_animation() -> void:
	is_wall_landing = false
	is_wall_sliding = false
	current_wall_side = 0


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
	if is_wall_landing or is_wall_sliding:
		return

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

	for available_animation in animation_player.get_animation_list():
		if String(available_animation).strip_edges() == String(animation_name).strip_edges():
			return StringName(available_animation)

	if animation_name == fall_animation and animation_player.has_animation(jump_animation):
		return jump_animation

	if animation_name == crouch_walk_animation and animation_player.has_animation(crouch_idle_animation):
		return crouch_idle_animation

	return StringName()


func has_animation(animation_name: StringName) -> bool:
	return animation_player != null and animation_player.has_animation(animation_name)


func has_landing_animation() -> bool:
	return has_animation(landing_animation)


func has_wall_land_animation(side: int) -> bool:
	return get_wall_land_animation(side) != StringName()


func has_wall_slide_animation(side: int) -> bool:
	return get_wall_slide_animation(side) != StringName()


func get_wall_land_animation(side: int) -> StringName:
	if side < 0:
		return resolve_animation_name(wall_land_left_animation)
	if side > 0:
		return resolve_animation_name(wall_land_right_animation)
	return StringName()


func get_wall_slide_animation(side: int) -> StringName:
	if side < 0:
		return resolve_animation_name(wall_slide_left_animation)
	if side > 0:
		return resolve_animation_name(wall_slide_right_animation)
	return StringName()


func reset_wall_flip() -> void:
	flip_h = false


func configure_wall_animation_loops() -> void:
	set_animation_loop_mode(wall_land_left_animation, Animation.LOOP_NONE)
	set_animation_loop_mode(wall_land_right_animation, Animation.LOOP_NONE)
	set_animation_loop_mode(wall_slide_left_animation, Animation.LOOP_LINEAR)
	set_animation_loop_mode(wall_slide_right_animation, Animation.LOOP_LINEAR)


func set_animation_loop_mode(animation_name: StringName, loop_mode: int) -> void:
	var resolved_animation: StringName = resolve_animation_name(animation_name)
	if resolved_animation == StringName() or animation_player == null:
		return

	animation_player.get_animation(resolved_animation).loop_mode = loop_mode


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
	var resolved_animation: StringName = resolve_animation_name(animation_name)

	if resolved_animation == resolve_animation_name(landing_animation):
		landing_finished.emit()
	elif resolved_animation == resolve_animation_name(punch_animation):
		_finish_attack()
	elif resolved_animation == get_wall_land_animation(-1):
		is_wall_landing = false
		current_wall_side = 0
		wall_land_finished.emit(-1)
	elif resolved_animation == get_wall_land_animation(1):
		is_wall_landing = false
		current_wall_side = 0
		wall_land_finished.emit(1)
