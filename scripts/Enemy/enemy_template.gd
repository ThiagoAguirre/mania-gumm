extends CharacterBody2D
class_name EnemyTemplate

signal kill

@onready var texture: Sprite2D = get_node("Texture")
@onready var floor_ray: RayCast2D = get_node("floorRay")
@onready var animation: AnimationPlayer = get_node("Animation")
@onready var attack_area: Area2D = get_node_or_null("AttackArea") as Area2D

var can_die: bool = false
var can_hit: bool = false
var can_attack: bool = false

var drop_bonus: int = 1
var attack_animation_suffix: String = "_left"
var floor_ray_base_position: Vector2 = Vector2.ZERO

var drop_list: Dictionary
var player_ref: Player = null

@export var speed: int
# @export var enemy_exp: int
@export var gravity_speed: int
@export var proximity_threshold: int
@export var raycast_default_position: int
@export var attack_damage: int = 1

# @export var floating_text: PackedScene

func _physics_process(delta: float) -> void:
	gravity(delta)
	verify_position()
	move_behavior()
	texture.animate(velocity)
	move_and_slide()


func _ready() -> void:
	floor_ray_base_position = floor_ray.position
	if animation != null and texture != null and texture.has_method("on_animation_finished"):
		var animation_finished_callable: Callable = Callable(texture, "on_animation_finished")
		if not animation.animation_finished.is_connected(animation_finished_callable):
			animation.animation_finished.connect(animation_finished_callable)

	if attack_area != null:
		var body_entered_callable: Callable = Callable(self, "_on_attack_area_body_entered")
		if not attack_area.body_entered.is_connected(body_entered_callable):
			attack_area.body_entered.connect(body_entered_callable)

	if texture != null and texture.attack_area_collision != null:
		texture.attack_area_collision.disabled = true
	
	
func gravity(delta: float) -> void:
	velocity.y += delta * gravity_speed
	
	
func move_behavior() -> void:
	if player_ref != null:
		var distance: Vector2 = player_ref.global_position - global_position
		var direction: Vector2 = distance.normalized()
		if abs(distance.x) <= proximity_threshold:
			velocity.x = 0
			can_attack = true
		elif floor_collision() and not can_attack:
			velocity.x = direction.x * speed
			
		else:
			velocity.x = 0
			
		return
		
	velocity.x = 0
	
	
func floor_collision() -> bool:
	floor_ray.force_raycast_update()
	if floor_ray.is_colliding():
		return true
		
	return false
	
	
func verify_position() -> void:
	if player_ref != null:
		var direction: float = sign(player_ref.global_position.x - global_position.x)
		
		if direction > 0:
			texture.flip_h = true
			attack_animation_suffix = "_right"
			floor_ray.position.x = absf(floor_ray_base_position.x)
		elif direction < 0:
			texture.flip_h = false
			attack_animation_suffix = "_left"
			floor_ray.position.x = -absf(floor_ray_base_position.x)


func kill_enemy() -> void:
	kill.emit()
	if animation != null and animation.has_animation("kill"):
		animation.play("kill")
	else:
		queue_free()


func _on_attack_area_body_entered(body: Node2D) -> void:
	if not can_attack or can_die:
		return

	var player: Player = body as Player
	if player == null:
		return

	player.take_damage(attack_damage, global_position)
	
	

	
