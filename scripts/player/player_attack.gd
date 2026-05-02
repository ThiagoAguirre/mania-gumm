extends CollisionShape2D

@export var animations_path: NodePath = ^"../../AnimatedSprite2D"
@export var hitbox_delay: float = 0.3
@export var hitbox_duration: float = 0.1

@onready var player_animations: PlayerAnimations = get_node_or_null(animations_path) as PlayerAnimations


func _ready() -> void:
	disabled = true


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("attack"):
		attack()


func attack() -> void:
	if player_animations == null:
		return

	if not player_animations.play_attack():
		return
