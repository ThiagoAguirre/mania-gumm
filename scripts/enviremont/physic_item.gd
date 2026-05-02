extends RigidBody2D
class_name PhysicItem 

@onready var sprite: Sprite2D = get_node("Texture")

const collect_effect: PackedScene = preload("res://scenes/effect/template/general_effects/collect_item.tscn")

var player_ref: CharacterBody2D = null

var item_name: String
var item_info_list: Array
var item_texture: CompressedTexture2D

func _ready() -> void:
	randomize()
	apply_random_impulse()
	
	
func apply_random_impulse() -> void:
	apply_impulse(
		Vector2.ZERO,
		Vector2(
			randf_range(-60, 60),
			-90
		)
	)
	
	
func update_item_info(key: String, texture: CompressedTexture2D, item_info: Array) -> void:
	await self.ready
	
	item_name = key
	item_texture = texture
	item_info_list = item_info
	
	sprite.texture = texture
	
	
func on_screen_exited():
	queue_free()
	
	
func on_body_entered(body: Node) -> void:
	var player: Player = body as Player
	if player == null:
		return

	player_ref = player
	
	
func on_body_exited(body: Node) -> void:
	if body != player_ref:
		return

	player_ref = null
	
func _process(_delta: float) -> void:
	if player_ref != null and Input.is_action_just_pressed("interact"):
		spawn_effect()
		queue_free()
		
func spawn_effect() -> void:
	var collect_effect: EffectTemplate = collect_effect.instantiate()
	get_tree().root.call_deferred("add_child", collect_effect)
	collect_effect.global_position = global_position
	collect_effect.play_effect()
