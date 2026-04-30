extends CharacterBody2D
class_name Player

signal game_over_requested

@export var speed: int = 150
@export var jump_velocity: float = -300.0
@export var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
@export var sprite_path: NodePath = ^"AnimatedSprite2D"
@export var stats_path: NodePath = ^"Stats"
@export var landing_min_fall_distance: float = 64.0
@export var wall_detector_path: NodePath = ^"RayCast2D"
@export var wall_slide_speed: float = 65.0
@export var wall_jump_force_x: float = 220.0
@export var wall_jump_force_y: float = -260.0
@export var wall_jump_control_lock_time: float = 0.12
@export var invulnerability_time: float = 1.5
@export var hurt_knockback_force: Vector2 = Vector2(90.0, -60.0)
@export var hurt_control_lock_time: float = 0.2
@export_file("*.tscn") var game_over_scene_path: String = ""

@onready var player_animations: PlayerAnimations = get_node_or_null(sprite_path) as PlayerAnimations
@onready var stats: PlayerStats = get_node_or_null(stats_path) as PlayerStats
@onready var wall_detector: RayCast2D = get_node_or_null(wall_detector_path) as RayCast2D

var is_landing: bool = false
var is_dead: bool = false
var is_invulnerable: bool = false
var is_tracking_fall: bool = false
var fall_start_y: float = 0.0
var is_wall_landing: bool = false
var is_wall_sliding: bool = false
var wall_side: int = 0
var facing_side: int = 1
var invulnerability_timer: float = 0.0
var hurt_control_lock_timer: float = 0.0
var wall_jump_control_lock_timer: float = 0.0
var wall_detector_base_position: Vector2 = Vector2.ZERO
var wall_detector_base_target: Vector2 = Vector2.ZERO
var damage_knockback_side: int = -1


func _ready() -> void:
	if player_animations != null:
		player_animations.landing_finished.connect(_on_landing_finished)
		player_animations.wall_land_finished.connect(_on_wall_land_finished)
		player_animations.death_finished.connect(_on_death_finished)

	if stats != null:
		stats.damaged.connect(_on_stats_damaged)
		stats.died.connect(_on_stats_died)

	if wall_detector != null:
		wall_detector.enabled = true
		wall_detector_base_position = wall_detector.position
		wall_detector_base_target = wall_detector.target_position


func _physics_process(delta: float) -> void:
	if is_dead:
		death_movement(delta)
		return

	if stats != null and stats.current_health <= 0:
		start_death()
		death_movement(delta)
		return

	update_invulnerability(delta)

	if hurt_control_lock_timer > 0.0:
		update_hurt_control_lock(delta)
		hurt_movement(delta)
		return

	var was_on_floor: bool = is_on_floor()

	if is_landing:
		landing_movement(delta)
		if player_animations != null:
			player_animations.play_landing()
		return

	var is_crouching: bool = is_crouch_pressed()
	var input_direction: float = get_horizontal_input()
	var jump_pressed: bool = Input.is_action_just_pressed("ui_accept")
	update_wall_detector_direction(input_direction)
	update_wall_jump_lock(delta)

	horizontal_movement_env(input_direction)
	handle_jump_input(jump_pressed)

	if not is_on_floor():
		velocity.y += gravity * delta

	limit_wall_slide_fall_speed()

	move_and_slide()
	update_wall_detection()
	limit_wall_slide_fall_speed()

	if was_on_floor and not is_on_floor():
		start_fall_tracking()

	var just_landed: bool = not was_on_floor and is_on_floor()
	if just_landed:
		wall_jump_control_lock_timer = 0.0
		stop_wall_state()

	if just_landed and should_play_landing():
		stop_fall_tracking()
		start_landing()
		return
	elif just_landed:
		stop_fall_tracking()

	update_animations(input_direction, is_crouching)


func horizontal_movement_env(input_direction: float) -> void:
	if wall_jump_control_lock_timer > 0.0:
		return

	velocity.x = input_direction * speed


func handle_jump_input(jump_pressed: bool) -> void:
	if not jump_pressed:
		return

	if is_wall_landing or is_wall_sliding:
		wall_jump()
	elif is_on_floor():
		stop_wall_state()
		velocity.y = jump_velocity


func wall_jump() -> void:
	var jump_wall_side: int = wall_side
	if jump_wall_side == 0:
		return

	stop_wall_state()
	wall_jump_control_lock_timer = wall_jump_control_lock_time
	velocity.x = -jump_wall_side * wall_jump_force_x
	velocity.y = wall_jump_force_y


func update_wall_jump_lock(delta: float) -> void:
	if wall_jump_control_lock_timer > 0.0:
		wall_jump_control_lock_timer = maxf(wall_jump_control_lock_timer - delta, 0.0)


func landing_movement(delta: float) -> void:
	velocity.x = 0.0

	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()


func hurt_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()


func death_movement(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, speed * delta)

	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()


func start_landing() -> void:
	stop_wall_state()
	is_landing = true
	velocity.x = 0.0
	if player_animations != null:
		player_animations.play_landing()


func start_fall_tracking() -> void:
	is_tracking_fall = true
	fall_start_y = position.y


func stop_fall_tracking() -> void:
	is_tracking_fall = false


func update_wall_detection() -> void:
	if is_on_floor() or velocity.y <= 0.0:
		stop_wall_state()
		return

	var detected_wall_side: int = get_wall_contact_side()
	if detected_wall_side == 0:
		stop_wall_state()
		return

	if is_wall_landing or is_wall_sliding:
		if detected_wall_side != wall_side:
			stop_wall_state()
			start_wall_land(detected_wall_side)
		return

	start_wall_land(detected_wall_side)


func limit_wall_slide_fall_speed() -> void:
	if not is_wall_landing and not is_wall_sliding:
		return

	if velocity.y > 0.0:
		velocity.y = minf(velocity.y, wall_slide_speed)


func start_wall_land(side: int) -> void:
	if side == 0 or player_animations == null or not player_animations.has_wall_land_animation(side):
		return

	is_wall_landing = true
	is_wall_sliding = false
	wall_side = side
	player_animations.play_wall_land(side)


func start_wall_slide(side: int) -> void:
	if side == 0 or player_animations == null or not player_animations.has_wall_slide_animation(side):
		stop_wall_state()
		return

	is_wall_landing = false
	is_wall_sliding = true
	wall_side = side
	player_animations.play_wall_slide(side)


func stop_wall_state() -> void:
	is_wall_landing = false
	is_wall_sliding = false
	wall_side = 0
	if player_animations != null:
		player_animations.stop_wall_animation()


func update_animations(input_direction: float, is_crouching: bool) -> void:
	if player_animations == null:
		return

	var animation_velocity: Vector2 = velocity
	animation_velocity.x = input_direction * speed
	player_animations.animate(animation_velocity, velocity, input_direction, is_crouching, is_on_floor())


func get_wall_contact_side() -> int:
	var collision_side: int = get_wall_side_from_slide_collision()
	if collision_side != 0:
		return collision_side

	return get_wall_side_from_raycast()


func update_wall_detector_direction(input_direction: float) -> void:
	if wall_detector == null:
		return

	if wall_side != 0:
		facing_side = wall_side
	elif input_direction > 0.0:
		facing_side = 1
	elif input_direction < 0.0:
		facing_side = -1
	elif velocity.x > 0.0:
		facing_side = 1
	elif velocity.x < 0.0:
		facing_side = -1

	set_wall_detector_side(facing_side)


func get_wall_side_from_raycast() -> int:
	if wall_detector == null:
		return 0

	if wall_side != 0 and is_raycast_colliding_to_side(wall_side):
		return wall_side

	if is_raycast_colliding_to_side(facing_side):
		return facing_side

	if is_raycast_colliding_to_side(-facing_side):
		return -facing_side

	set_wall_detector_side(facing_side)
	return 0


func is_raycast_colliding_to_side(side: int) -> bool:
	if wall_detector == null or side == 0:
		return false

	set_wall_detector_side(side)
	wall_detector.force_raycast_update()
	return wall_detector.is_colliding()


func set_wall_detector_side(side: int) -> void:
	if wall_detector == null or side == 0:
		return

	var target: Vector2 = wall_detector_base_target
	var detector_position: Vector2 = wall_detector_base_position
	detector_position.x = absf(wall_detector_base_position.x) * side
	target.x = absf(wall_detector_base_target.x) * side
	wall_detector.position = detector_position
	wall_detector.target_position = target


func get_wall_side_from_slide_collision() -> int:
	for collision_index in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(collision_index)
		if collision == null:
			continue

		var normal_x: float = collision.get_normal().x
		if normal_x > 0.5:
			return -1
		if normal_x < -0.5:
			return 1

	return 0


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


func take_damage(amount: int, damage_origin: Vector2 = Vector2.ZERO) -> int:
	if stats == null or is_dead or is_invulnerable:
		return 0

	damage_knockback_side = get_knockback_side(damage_origin)
	return stats.take_damage(amount)


func get_knockback_side(damage_origin: Vector2) -> int:
	if damage_origin != Vector2.ZERO:
		var side_from_origin: float = signf(global_position.x - damage_origin.x)
		if side_from_origin != 0.0:
			return int(side_from_origin)

	return -facing_side


func update_invulnerability(delta: float) -> void:
	if not is_invulnerable:
		return

	invulnerability_timer = maxf(invulnerability_timer - delta, 0.0)
	if invulnerability_timer <= 0.0:
		is_invulnerable = false


func update_hurt_control_lock(delta: float) -> void:
	hurt_control_lock_timer = maxf(hurt_control_lock_timer - delta, 0.0)


func start_invulnerability() -> void:
	is_invulnerable = true
	invulnerability_timer = invulnerability_time


func apply_hurt_knockback() -> void:
	stop_wall_state()
	is_landing = false
	hurt_control_lock_timer = hurt_control_lock_time
	velocity.x = hurt_knockback_force.x * damage_knockback_side
	velocity.y = minf(velocity.y, hurt_knockback_force.y)


func start_death() -> void:
	if is_dead:
		return

	is_dead = true
	is_invulnerable = false
	invulnerability_timer = 0.0
	hurt_control_lock_timer = 0.0
	stop_wall_state()
	is_landing = false
	velocity.x = 0.0

	if player_animations == null or not player_animations.play_death():
		_on_death_finished()


func _on_landing_finished() -> void:
	is_landing = false


func _on_wall_land_finished(side: int) -> void:
	if side != wall_side or is_on_floor():
		stop_wall_state()
		return

	if velocity.y <= 0.0 or get_wall_contact_side() != side:
		stop_wall_state()
		return

	start_wall_slide(side)


func _on_stats_damaged(_damage_taken: int, current_health: int, _max_health: int) -> void:
	if current_health <= 0:
		start_death()
		return

	start_invulnerability()
	apply_hurt_knockback()

	if player_animations != null:
		player_animations.play_hurt()


func _on_stats_died() -> void:
	start_death()


func _on_death_finished() -> void:
	game_over_requested.emit()

	if game_over_scene_path != "":
		get_tree().change_scene_to_file(game_over_scene_path)
	else:
		get_tree().reload_current_scene()
