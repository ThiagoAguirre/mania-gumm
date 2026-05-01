extends Node
class_name PlayerStats

signal health_changed(current_health: int, max_health: int)
signal mana_changed(current_mana: int, max_mana: int)
signal damaged(damage_taken: int, current_health: int, max_health: int)
signal died
signal exp_changed(current_exp: int, required_exp: int, level: int)
signal leveled_up(new_level: int)

const MAX_LEVEL: int = 9

@export var base_health: int = 15
@export var base_mana: int = 10
@export var base_attack: int = 1
@export var base_magic_attack: int = 3
@export var base_defense: int = 1

@export var bonus_health: int = 0
@export var bonus_mana: int = 0
@export var bonus_attack: int = 0
@export var bonus_magic_attack: int = 0
@export var bonus_defense: int = 0

@export var floating_text: PackedScene
@export var player: Player = null
@export var collision_area: Area2D = null

var shielding: bool = false
var current_mana: int = 0
var current_health: int = 0
var max_mana: int = 0
var max_health: int = 0
var current_exp: int = 0
var level: int = 1

var level_dict: Dictionary = {
	1: 25,
	2: 33,
	3: 49,
	4: 66,
	5: 93,
	6: 135,
	7: 186,
	8: 251,
	9: 356
}


func _ready() -> void:
	if player == null:
		player = get_parent() as Player

	if collision_area == null and get_parent() != null:
		collision_area = get_parent().get_node_or_null("CollisionArea") as Area2D

	recalculate_stats(true)
	_connect_player_signals()


func recalculate_stats(restore_resources: bool = false) -> void:
	var previous_max_health: int = max_health
	var previous_max_mana: int = max_mana

	max_health = base_health + bonus_health
	max_mana = base_mana + bonus_mana

	if restore_resources or previous_max_health <= 0:
		current_health = max_health
	else:
		current_health = clampi(current_health, 0, max_health)

	if restore_resources or previous_max_mana <= 0:
		current_mana = max_mana
	else:
		current_mana = clampi(current_mana, 0, max_mana)

	health_changed.emit(current_health, max_health)
	mana_changed.emit(current_mana, max_mana)
	exp_changed.emit(current_exp, get_required_exp(), level)


func get_attack() -> int:
	return base_attack + bonus_attack


func get_magic_attack() -> int:
	return base_magic_attack + bonus_magic_attack


func get_defense() -> int:
	return base_defense + bonus_defense


func take_damage(amount: int) -> int:
	if amount <= 0 or current_health <= 0:
		return 0

	var damage_taken: int = verify_shield(amount)
	if damage_taken <= 0:
		health_changed.emit(current_health, max_health)
		return 0

	current_health = clampi(current_health - damage_taken, 0, max_health)
	damaged.emit(damage_taken, current_health, max_health)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		died.emit()

	return damage_taken


func heal(amount: int) -> int:
	if amount <= 0 or current_health >= max_health:
		return 0

	var previous_health: int = current_health
	current_health = clampi(current_health + amount, 0, max_health)
	var healed_amount: int = current_health - previous_health
	health_changed.emit(current_health, max_health)
	return healed_amount


func spend_mana(amount: int) -> bool:
	if amount < 0:
		return false

	if current_mana < amount:
		return false

	current_mana -= amount
	mana_changed.emit(current_mana, max_mana)
	return true


func restore_mana(amount: int) -> int:
	if amount <= 0 or current_mana >= max_mana:
		return 0

	var previous_mana: int = current_mana
	current_mana = clampi(current_mana + amount, 0, max_mana)
	var restored_amount: int = current_mana - previous_mana
	mana_changed.emit(current_mana, max_mana)
	return restored_amount


func update_health(change_type: String, value: int) -> void:
	match change_type.to_lower():
		"increase":
			heal(value)
		"decrease":
			take_damage(value)
		_:
			push_warning("update_health recebeu tipo invalido: %s" % change_type)


func verify_shield(value: int) -> int:
	var damage_after_defense: int = maxi(value - get_defense(), 1)

	if shielding:
		damage_after_defense = maxi(damage_after_defense - get_defense(), 0)

	return damage_after_defense


func update_exp(value: int) -> void:
	if value <= 0:
		return

	current_exp += value

	while level < MAX_LEVEL and current_exp >= get_required_exp():
		current_exp -= get_required_exp()
		level += 1
		on_level_up()

	if level >= MAX_LEVEL:
		current_exp = mini(current_exp, get_required_exp())

	exp_changed.emit(current_exp, get_required_exp(), level)


func on_level_up() -> void:
	recalculate_stats(true)
	leveled_up.emit(level)


func get_required_exp() -> int:
	return int(level_dict.get(level, level_dict[MAX_LEVEL]))


func on_collision_area_entered(area: Area2D) -> void:
	if area == null or player == null or player.player_animations == null:
		return

	if not player.player_animations.is_attacking:
		return

	var enemy: EnemyTemplate = area.get_parent() as EnemyTemplate
	if enemy == null:
		return

	enemy.can_hit = true
	enemy.set_physics_process(false)


func _connect_player_signals() -> void:
	if player == null:
		return

	if player.has_method("_on_stats_damaged"):
		var damaged_callable: Callable = Callable(player, "_on_stats_damaged")
		if not damaged.is_connected(damaged_callable):
			damaged.connect(damaged_callable)

	if player.has_method("_on_stats_died"):
		var died_callable: Callable = Callable(player, "_on_stats_died")
		if not died.is_connected(died_callable):
			died.connect(died_callable)
