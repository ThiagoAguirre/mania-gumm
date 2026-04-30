extends AnimatedSprite2D
class_name PlayerAnimations

signal landing_finished
signal attack_finished
signal wall_land_finished(side: int)
signal hurt_finished
signal death_finished

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
@export var hurt_animation: StringName = &"hurt"
@export var death_animation: StringName = &"death"
@export var wall_land_left_animation: StringName = &"wall_land_left"
@export var wall_land_right_animation: StringName = &"wall_land_right"
@export var wall_slide_left_animation: StringName = &"wall_slide_left"
@export var wall_slide_right_animation: StringName = &"wall_slide_right"
@export var wall_slide_loop_duration: float = 4.0

@onready var animation_player: AnimationPlayer = get_node_or_null(animation_player_path) as AnimationPlayer

var is_attacking: bool = false
var is_hurt: bool = false
var is_dead: bool = false
var is_wall_landing: bool = false
var is_wall_sliding: bool = false
var current_wall_side: int = 0


func _ready() -> void:
	stop()
	animation_finished.connect(_on_sprite_animation_finished)
	if animation_player != null:
		animation_player.animation_finished.connect(_on_animation_finished)
		configure_wall_animation_loops()
	configure_life_animation_loops()


func animate(facing_velocity: Vector2, current_velocity: Vector2, input_direction: float, is_crouching: bool, on_floor: bool) -> void:
	if is_dead or is_hurt:
		return

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
	if is_dead or is_hurt:
		return

	is_attacking = false
	play_animation(landing_animation)


func play_wall_land(side: int) -> bool:
	if is_dead or is_hurt:
		return false

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
	if is_dead or is_hurt:
		return false

	var animation_name: StringName = get_wall_slide_animation(side)
	if animation_name == StringName():
		return false

	is_wall_landing = false
	is_wall_sliding = true
	current_wall_side = side
	reset_wall_flip()
	set_animation_loop_mode(animation_name, Animation.LOOP_LINEAR)
	play_animation(animation_name, true, get_animation_speed_for_duration(animation_name, wall_slide_loop_duration))
	return true


func stop_wall_animation() -> void:
	is_wall_landing = false
	is_wall_sliding = false
	current_wall_side = 0


func play_attack() -> bool:
	if is_attacking or is_hurt or is_dead:
		return false

	if not has_animation(punch_animation):
		return false

	is_attacking = true
	play_animation(punch_animation, true)
	_finish_attack_after_animation()
	return true


func play_hurt() -> bool:
	if is_dead or not has_life_animation(hurt_animation):
		return false

	is_attacking = false
	is_hurt = true
	stop_wall_animation()
	play_life_animation(hurt_animation)
	return true


func play_death() -> bool:
	if is_dead:
		return false

	is_attacking = false
	is_hurt = false
	is_dead = true
	stop_wall_animation()
	play_life_animation(death_animation)
	return true


func update_animation(current_velocity: Vector2, input_direction: float, is_crouching: bool, on_floor: bool) -> void:
	if is_dead or is_hurt:
		return

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


func play_animation(animation_name: StringName, restart: bool = false, custom_speed: float = 1.0) -> void:
	if animation_player == null:
		return

	var resolved_animation: StringName = resolve_animation_name(animation_name)
	if resolved_animation == StringName():
		resolved_animation = resolve_animation_name(idle_animation)

	if resolved_animation == StringName():
		return

	if restart:
		animation_player.stop()

	if restart or animation_player.current_animation != resolved_animation or not animation_player.is_playing():
		animation_player.play(resolved_animation, -1.0, custom_speed)


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


func has_sprite_animation(animation_name: StringName) -> bool:
	return sprite_frames != null and sprite_frames.has_animation(animation_name)


func has_life_animation(animation_name: StringName) -> bool:
	return has_animation(animation_name) or has_sprite_animation(animation_name)


func has_landing_animation() -> bool:
	return has_animation(landing_animation)


func has_hurt_animation() -> bool:
	return has_life_animation(hurt_animation)


func has_death_animation() -> bool:
	return has_life_animation(death_animation)


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


func configure_life_animation_loops() -> void:
	set_animation_loop_mode(hurt_animation, Animation.LOOP_NONE)
	set_animation_loop_mode(death_animation, Animation.LOOP_NONE)

	if sprite_frames == null:
		return

	if sprite_frames.has_animation(hurt_animation):
		sprite_frames.set_animation_loop(hurt_animation, false)
	if sprite_frames.has_animation(death_animation):
		sprite_frames.set_animation_loop(death_animation, false)


func set_animation_loop_mode(animation_name: StringName, loop_mode: int) -> void:
	var resolved_animation: StringName = resolve_animation_name(animation_name)
	if resolved_animation == StringName() or animation_player == null:
		return

	animation_player.get_animation(resolved_animation).loop_mode = loop_mode


func get_animation_speed_for_duration(animation_name: StringName, target_duration: float) -> float:
	if target_duration <= 0.0 or animation_player == null:
		return 1.0

	var resolved_animation: StringName = resolve_animation_name(animation_name)
	if resolved_animation == StringName():
		return 1.0

	var animation_length: float = animation_player.get_animation(resolved_animation).length
	if animation_length <= 0.0:
		return 1.0

	return animation_length / target_duration


func play_life_animation(animation_name: StringName) -> void:
	if animation_player != null and animation_player.has_animation(animation_name):
		play_animation(animation_name, true)
		return

	if not has_sprite_animation(animation_name):
		finish_life_animation(animation_name)
		return

	if animation_player != null:
		animation_player.stop()

	play(animation_name)


func finish_life_animation(animation_name: StringName) -> void:
	if animation_name == hurt_animation:
		is_hurt = false
		hurt_finished.emit()
	elif animation_name == death_animation:
		death_finished.emit()


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
	elif resolved_animation == resolve_animation_name(hurt_animation):
		finish_life_animation(hurt_animation)
	elif resolved_animation == resolve_animation_name(death_animation):
		finish_life_animation(death_animation)
	elif resolved_animation == get_wall_land_animation(-1):
		is_wall_landing = false
		current_wall_side = 0
		wall_land_finished.emit(-1)
	elif resolved_animation == get_wall_land_animation(1):
		is_wall_landing = false
		current_wall_side = 0
		wall_land_finished.emit(1)


func _on_sprite_animation_finished() -> void:
	if animation == hurt_animation:
		finish_life_animation(hurt_animation)
	elif animation == death_animation:
		finish_life_animation(death_animation)
