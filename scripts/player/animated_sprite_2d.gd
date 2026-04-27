extends AnimatedSprite2D
class_name PlayerAnimatedSprite

@export var idle_animation: StringName = &"idle"
@export var run_animation: StringName = &"run"
@export var jump_animation: StringName = &"jump"
@export var fall_animation: StringName = &"jump"
@export var landing_animation: StringName = &"landing"
@export var crouch_idle_animation: StringName = &"crouch_idle"
@export var crouch_walk_animation: StringName = &"crouch_walk"

# Landing temporariamente desativado.
# var is_landing: bool = false


func _ready() -> void:
	# Landing temporariamente desativado.
	# if sprite_frames != null and sprite_frames.has_animation(landing_animation):
	# 	sprite_frames.set_animation_loop(landing_animation, false)
	#
	# animation_finished.connect(_on_animation_finished)
	pass


func animate(current_velocity: Vector2, is_on_floor: bool, just_landed: bool, is_crouching: bool) -> void:
	verify_position(current_velocity)

	# Landing temporariamente desativado.
	# if is_landing:
	# 	return

	vertical_behavior(current_velocity, is_on_floor, just_landed, is_crouching)


func verify_position(current_velocity: Vector2) -> void:
	if current_velocity.x > 0.0:
		flip_h = false
	elif current_velocity.x < 0.0:
		flip_h = true


func horizontal_behavior(current_velocity: Vector2, is_crouching: bool) -> void:
	if is_crouching:
		crouch_behavior(current_velocity)
	elif current_velocity.x != 0.0:
		play_animation(run_animation)
	else:
		play_animation(idle_animation)


func crouch_behavior(current_velocity: Vector2) -> void:
	if current_velocity.x != 0.0:
		play_animation(crouch_walk_animation)
	else:
		play_animation(crouch_idle_animation)


func vertical_behavior(current_velocity: Vector2, is_on_floor: bool, _just_landed: bool, is_crouching: bool) -> void:
	# Landing temporariamente desativado.
	# if just_landed:
	# 	if has_animation(landing_animation):
	# 		is_landing = true
	# 		play_animation(landing_animation)
	# 	else:
	# 		horizontal_behavior(current_velocity, is_crouching)
	# elif not is_on_floor and current_velocity.y < 0.0:
	if not is_on_floor and current_velocity.y < 0.0:
		play_animation(jump_animation)
	elif not is_on_floor and current_velocity.y > 0.0:
		play_animation(fall_animation)
	else:
		horizontal_behavior(current_velocity, is_crouching)


func play_animation(animation_name: StringName) -> void:
	if sprite_frames == null:
		return

	if has_animation(animation_name):
		if animation != animation_name or not is_playing():
			play(animation_name)
	elif has_animation(idle_animation):
		if animation != idle_animation or not is_playing():
			play(idle_animation)


func has_animation(animation_name: StringName) -> bool:
	return sprite_frames != null and sprite_frames.has_animation(animation_name)


# Landing temporariamente desativado.
# func _on_animation_finished() -> void:
# 	if animation == landing_animation:
# 		is_landing = false
