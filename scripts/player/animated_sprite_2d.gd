extends AnimatedSprite2D
class_name PlayerAnimatedSprite

@export var idle_animation: StringName = &"idle"
@export var run_animation: StringName = &"run"
@export var jump_animation: StringName = &"jump"
@export var fall_animation: StringName = &"jump"
@export var landing_animation: StringName = &"landing"
@export var crouch_idle_animation: StringName = &"crouch_idle"
@export var crouch_walk_animation: StringName = &"crouch_walk"
@export var animation_player_path: NodePath = ^"../AnimationPlayer"

# Landing temporariamente desativado.
# var is_landing: bool = false

@onready var animation_player: AnimationPlayer = get_node_or_null(animation_player_path) as AnimationPlayer


func _ready() -> void:
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
	if animation_player == null:
		return

	var resolved_animation: StringName = resolve_animation_name(animation_name)
	if resolved_animation != StringName():
		if animation_player.current_animation != resolved_animation or not animation_player.is_playing():
			animation_player.play(resolved_animation)
		return

	var fallback_animation: StringName = resolve_animation_name(idle_animation)
	if fallback_animation != StringName():
		if animation_player.current_animation != fallback_animation or not animation_player.is_playing():
			animation_player.play(fallback_animation)


func resolve_animation_name(animation_name: StringName) -> StringName:
	if animation_name == StringName():
		return StringName()

	if animation_player.has_animation(animation_name):
		return animation_name

	if animation_name == fall_animation and animation_player.has_animation(jump_animation):
		return jump_animation

	if animation_name == crouch_walk_animation and animation_player.has_animation(crouch_idle_animation):
		return crouch_idle_animation

	return StringName()


# Landing temporariamente desativado.
# func _on_animation_finished() -> void:
# 	if animation == landing_animation:
# 		is_landing = false
