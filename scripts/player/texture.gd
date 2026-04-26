extends Sprite2D
class_name PlayerTexture

@export_node_path("AnimationPlayer") var animation_path: NodePath = ^"../Animation"
@export var idle_animation: StringName = &"idle"
@export var run_animation: StringName = &"run"
@export var jump_animation: StringName = &"jump"
@export var fall_animation: StringName = &"fall"
@export var landing_animation: StringName = &"landing"

@onready var animation: AnimationPlayer = get_node(animation_path)


func animate(current_velocity: Vector2, is_on_floor: bool, just_landed: bool) -> void:
	verify_position(current_velocity)

	if animation.has_animation(landing_animation) and animation.current_animation == landing_animation and animation.is_playing():
		return

	vertical_behavior(current_velocity, is_on_floor, just_landed)


func verify_position(current_velocity: Vector2) -> void:
	if current_velocity.x > 0:
		flip_h = false
	elif current_velocity.x < 0:
		flip_h = true


func horizontal_behavior(current_velocity: Vector2) -> void:
	if current_velocity.x != 0:
		play_animation(run_animation)
	else:
		play_animation(idle_animation)


func vertical_behavior(current_velocity: Vector2, is_on_floor: bool, just_landed: bool) -> void:
	if just_landed:
		play_animation(landing_animation)
	elif not is_on_floor and current_velocity.y < 0:
		play_animation(jump_animation)
	elif not is_on_floor and current_velocity.y > 0:
		play_animation(fall_animation)
	else:
		horizontal_behavior(current_velocity)


func play_animation(animation_name: StringName) -> void:
	if animation.has_animation(animation_name):
		if animation.current_animation != animation_name:
			animation.play(animation_name)
	elif animation.has_animation(idle_animation):
		if animation.current_animation != idle_animation:
			animation.play(idle_animation)
