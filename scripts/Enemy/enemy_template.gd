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
var has_processed_kill: bool = false

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

	if animation != null:
		var enemy_animation_finished_callable: Callable = Callable(self, "_on_animation_finished")
		if not animation.animation_finished.is_connected(enemy_animation_finished_callable):
			animation.animation_finished.connect(enemy_animation_finished_callable)

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
	if has_processed_kill:
		return

	kill.emit()
	if animation != null and animation.has_animation("kill"):
		animation.play("kill")
	else:
		has_processed_kill = true
		spawn_item_probability()
		queue_free()


func _on_animation_finished(anim_name: String) -> void:
	if anim_name != "kill" or has_processed_kill:
		return

	has_processed_kill = true
	spawn_item_probability()


func _on_attack_area_body_entered(body: Node2D) -> void:
	if not can_attack or can_die:
		return

	var player: Player = body as Player
	if player == null:
		return

	player.take_damage(attack_damage, global_position)
	
func spawn_item_probability() -> void:
	var random_number: int = randi() % 21
	if random_number  <= 6:
		drop_bonus = 1
	elif random_number >= 7 and random_number <= 13:
		drop_bonus = 2
	else:
		drop_bonus = 3
	print("Multiplicador de Drop: " + str(drop_bonus))
	
	for key in drop_list.keys():
		var rng: int = randi() % 100 + 1
		if rng <= drop_list[key][1] * drop_bonus:
			var item_texture: CompressedTexture2D = load(drop_list[key][0])
			var item_info: Array = [
				drop_list[key][0], 
				drop_list[key][2], 
				drop_list[key][3], 
				drop_list[key][4], 
				1
			]
			
			spawn_physic_item(key, item_texture, item_info)

func spawn_physic_item(key: String, item_texture: CompressedTexture2D, item_info: Array) -> void:
	var physic_item_scene: PackedScene = load("res://scenes/enviroment/physic_item.tscn")
	if physic_item_scene == null:
		push_error("Physic item scene not found while spawning drop for %s" % key)
		return

	var item: PhysicItem = physic_item_scene.instantiate()
	if item == null:
		push_error("Failed to instantiate physic item for %s" % key)
		return

	get_parent().call_deferred("add_child", item)
	item.global_position = global_position
	item.update_item_info(key, item_texture, item_info)
	
