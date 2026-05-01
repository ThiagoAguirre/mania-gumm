extends Area2D
class_name CollisionArea


@onready var timer: Timer = get_node("Timer")

@export var health: int
@export var invulnerability_timer: float = 0.5
@export var enemy: CharacterBody2D = null
@export var enemy_bar: Control = null

var is_invulnerable: bool = false
var last_attack_sequence_by_player: Dictionary = {}


func _ready() -> void:
	if enemy == null:
		enemy = get_parent() as CharacterBody2D

	timer.one_shot = true
	timer.wait_time = invulnerability_timer

	var timeout_callable: Callable = Callable(self, "_on_timer_timeout")
	if not timer.timeout.is_connected(timeout_callable):
		timer.timeout.connect(timeout_callable)

func on_area_entered(area: Area2D) -> void:
	if is_invulnerable or health <= 0:
		return

	var player: Player = area.get_parent() as Player
	if player == null:
		return

	var player_attack_area: Area2D = player.get_node_or_null("AttackArea") as Area2D
	if player_attack_area == null or area != player_attack_area:
		return

	var player_stats: PlayerStats = player.get_node("Stats") as PlayerStats
	var player_animations: PlayerAnimations = player.get_node("AnimatedSprite2D") as PlayerAnimations
	if player_stats == null or player_animations == null:
		return

	if not player_animations.is_attacking:
		return

	var player_instance_id: int = player.get_instance_id()
	var attack_sequence: int = player_animations.attack_sequence
	var last_attack_sequence: int = int(last_attack_sequence_by_player.get(player_instance_id, -1))
	if attack_sequence == last_attack_sequence:
		return

	last_attack_sequence_by_player[player_instance_id] = attack_sequence

	var player_attack: int = player_stats.get_attack()
	update_health(player_attack)

func update_health(damage: int) -> void:
	print("INIMIGO TOMOU DANO: ", damage, " | VIDA ANTES: ", health)
	health -= damage
	if enemy_bar != null and enemy_bar.has_method("update_bar"):
		enemy_bar.update_bar(health)
	
	if health <= 0:
		enemy.can_die = true
		return

	is_invulnerable = true
	timer.start()
	enemy.can_hit = true
	enemy.set_physics_process(false)


func _on_timer_timeout() -> void:
	is_invulnerable = false
