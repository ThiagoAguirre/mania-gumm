extends CollisionShape2D

@export var animations_path: NodePath = ^"../../AnimatedSprite2D"
@export var hitbox_delay: float = 0.3
@export var hitbox_duration: float = 0.1

@onready var player_animations: PlayerAnimations = get_node_or_null(animations_path) as PlayerAnimations

var attack_id: int = 0


func _ready() -> void:
	disabled = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		attack()


func attack() -> void:
	if player_animations == null:
		return

	if not player_animations.play_attack():
		return

	attack_id += 1
	run_hitbox_window(attack_id)


func run_hitbox_window(current_attack_id: int) -> void:
	disabled = true

	await get_tree().create_timer(hitbox_delay).timeout
	if current_attack_id != attack_id:
		return

	disabled = false

	await get_tree().create_timer(hitbox_duration).timeout
	if current_attack_id != attack_id:
		return

	disabled = true
