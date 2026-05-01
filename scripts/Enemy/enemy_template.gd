extends CharacterBody2D
class_name EnemyTemplate

signal kill

@onready var texture: Sprite2D = get_node("Texture")
@onready var floor_ray: RayCast2D = get_node("floorRay")
@onready var animation: AnimationPlayer = get_node("Animation")

var can_die: bool = false
var can_hit: bool = false
var can_attack: bool = false

var drop_bonus: int = 1
var attack_animation_suffix: String = "_left"

var drop_list: Dictionary
var player_ref: Player = null

@export var speed: int
# @export var enemy_exp: int
@export var gravity_speed: int
@export var proximity_threshold: int
@export var raycast_default_position: int

# @export var floating_text: PackedScene

func _physics_process(delta: float) -> void:
	gravity(delta)
	move_behavior()
	verify_position()
	texture.animate(velocity)
	move_and_slide()
	
	
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
	if floor_ray.is_colliding():
		return true
		
	return false
	
	
func verify_position() -> void:
	if player_ref != null:
		var direction: float = sign(player_ref.global_position.x - global_position.x)
		
		if direction > 0:
			texture.flip_h = true
			attack_animation_suffix = "_right"
			floor_ray.position.x = abs(raycast_default_position)
		elif direction < 0:
			texture.flip_h = false
			attack_animation_suffix = "_left"
			floor_ray.position.x = raycast_default_position
	
	

	
