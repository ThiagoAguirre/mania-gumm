extends CharacterBody2D
class_name Player

@export var speed: int = 150
@export var jump_velocity: float = -300.0
@export var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
@export var sprite_path: NodePath = ^"AnimatedSprite2D"
@export var landing_min_fall_distance: float = 64.0
@export var wall_detector_path: NodePath = ^"RayCast2D"
@export_range(0.0, 1.0, 0.05) var wall_slide_gravity_scale: float = 0.35

@onready var player_animations: PlayerAnimations = get_node_or_null(sprite_path) as PlayerAnimations
@onready var wall_detector: RayCast2D = get_node_or_null(wall_detector_path) as RayCast2D

var is_landing: bool = false
var is_tracking_fall: bool = false
var fall_start_y: float = 0.0
var is_wall_landing: bool = false
var is_wall_sliding: bool = false
var wall_side: int = 0
var wall_detector_base_target: Vector2 = Vector2.ZERO


func _ready() -> void:
	if player_animations != null:
		player_animations.landing_finished.connect(_on_landing_finished)
		player_animations.wall_land_finished.connect(_on_wall_land_finished)

	if wall_detector != null:
		wall_detector_base_target = wall_detector.target_position


func _physics_process(_delta: float) -> void:
	var was_on_floor: bool = is_on_floor()
	var was_wall_active: bool = is_wall_landing or is_wall_sliding

	if is_landing:
		landing_movement(_delta)
		if player_animations != null:
			player_animations.play_landing()
		return

	var is_crouching: bool = is_crouch_pressed()
	var input_direction: float = get_horizontal_input()

	horizontal_movement_env(input_direction)

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		stop_wall_state()
		velocity.y = jump_velocity

	if not is_on_floor():
		velocity.y += get_current_gravity() * _delta

	move_and_slide()
	update_wall_detection()

	if was_on_floor and not is_on_floor():
		start_fall_tracking()

	var just_landed: bool = not was_on_floor and is_on_floor()
	if just_landed:
		stop_wall_state()

	if just_landed and should_play_landing():
		stop_fall_tracking()
		start_landing()
		return
	elif just_landed:
		stop_fall_tracking()

	if was_wall_active and not is_wall_landing and not is_wall_sliding:
		update_wall_detection()

	update_animations(input_direction, is_crouching)


func horizontal_movement_env(input_direction: float) -> void:
	velocity.x = input_direction * speed


func landing_movement(delta: float) -> void:
	velocity.x = 0.0

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


func get_current_gravity() -> float:
	if is_wall_landing or is_wall_sliding:
		return gravity * wall_slide_gravity_scale

	return gravity


func get_wall_contact_side() -> int:
	var raycast_side: int = get_wall_side_from_raycast()
	if raycast_side != 0:
		return raycast_side

	return get_wall_side_from_slide_collision()


func get_wall_side_from_raycast() -> int:
	if wall_detector == null:
		return 0

	var right_target: Vector2 = wall_detector_base_target
	right_target.x = absf(wall_detector_base_target.x)
	if is_raycast_hitting(right_target):
		return 1

	var left_target: Vector2 = wall_detector_base_target
	left_target.x = -absf(wall_detector_base_target.x)
	if is_raycast_hitting(left_target):
		return -1

	return 0


func is_raycast_hitting(target_position: Vector2) -> bool:
	if wall_detector == null:
		return false

	wall_detector.target_position = target_position
	wall_detector.force_raycast_update()
	return wall_detector.is_colliding()


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
