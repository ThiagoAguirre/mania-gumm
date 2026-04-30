extends Node
class_name PlayerStats

signal experience_changed(current_experience: int, current_level: int, experience_to_next_level: int)
signal level_changed(new_level: int)
signal health_changed(current_health: int, max_health: int)
signal damaged(damage_taken: int, current_health: int, max_health: int)
signal died

enum PlayerClass {
	NONE,
	WARRIOR,
	MAGE,
	ROGUE,
	CLERIC,
}

const CLASS_STATS: Dictionary = {
	PlayerClass.NONE: {},
	PlayerClass.WARRIOR: {
		"strength": 2,
		"constitution": 1,
		"base_damage": 3,
		"base_defense": 2,
	},
	PlayerClass.MAGE: {
		"intelligence": 3,
		"base_mana": 15,
		"base_magic_damage": 4,
	},
	PlayerClass.ROGUE: {
		"dexterity": 3,
		"base_damage": 2,
	},
	PlayerClass.CLERIC: {
		"wisdom": 3,
		"base_mana": 10,
		"base_magic_defense": 3,
	},
}

const EXPERIENCE_BY_LEVEL: Array[int] = [
	0,
	300,
	900,
	2700,
	6500,
	14000,
	23000,
	34000,
	48000,
	64000,
	85000,
	100000,
	120000,
	140000,
	165000,
	195000,
	225000,
	265000,
	305000,
	355000,
]

const PROFICIENCY_BY_LEVEL: Array[int] = [
	2,
	2,
	2,
	2,
	3,
	3,
	3,
	3,
	4,
	4,
	4,
	4,
	5,
	5,
	5,
	5,
	6,
	6,
	6,
	6,
]

@export_group("Class")
@export_enum("None", "Warrior", "Mage", "Rogue", "Cleric") var player_class: int = PlayerClass.NONE:
	set(value):
		player_class = value
		if is_node_ready():
			apply_class_stats()
			reset_current_stats()

@export_group("Level")
@export_range(1, 20, 1) var level: int = 1
@export var experience: int = 0

@export_group("Attributes")
## Attributes are the character's core values. They exist for every class.
@export var strength: int = 10
@export var dexterity: int = 10
@export var constitution: int = 10
@export var charisma: int = 10
@export var wisdom: int = 10
@export var intelligence: int = 10

@export_group("Base Stats")
## Base stats are the character's starting numbers before class, equipment, buffs, or debuffs.
@export var base_health: int = 20
@export var base_mana: int = 10
@export var base_damage: int = 2
@export var base_magic_damage: int = 0
@export var base_defense: int = 0
@export var base_magic_defense: int = 0

@export_group("Current Stats")
## Current stats are runtime values that change during gameplay.
@export var current_health: int = 0
@export var current_mana: int = 0
@export var current_defense: int = 0
@export var current_magic_defense: int = 0

@export_group("Calculated Stats")
@export var max_health: int = 0
@export var max_mana: int = 0

var class_strength_bonus: int = 0
var class_dexterity_bonus: int = 0
var class_constitution_bonus: int = 0
var class_charisma_bonus: int = 0
var class_wisdom_bonus: int = 0
var class_intelligence_bonus: int = 0
var class_health_bonus: int = 0
var class_mana_bonus: int = 0
var class_damage_bonus: int = 0
var class_magic_damage_bonus: int = 0
var class_defense_bonus: int = 0
var class_magic_defense_bonus: int = 0

# Equipment bonuses should be connected here when inventory/equipment exists.
var equipment_damage_bonus: int = 0
var equipment_magic_damage_bonus: int = 0
var equipment_defense_bonus: int = 0
var equipment_magic_defense_bonus: int = 0

# Buff/debuff bonuses should be connected here when temporary effects exist.
var buff_health_bonus: int = 0
var buff_mana_bonus: int = 0
var buff_damage_bonus: int = 0
var buff_magic_damage_bonus: int = 0
var buff_defense_bonus: int = 0
var buff_magic_defense_bonus: int = 0


func _ready() -> void:
	set_experience(experience)
	apply_class_stats()
	reset_current_stats()


func apply_class_stats() -> void:
	reset_class_bonuses()

	var stats: Dictionary = CLASS_STATS.get(player_class, {})
	class_strength_bonus = stats.get("strength", 0)
	class_dexterity_bonus = stats.get("dexterity", 0)
	class_constitution_bonus = stats.get("constitution", 0)
	class_charisma_bonus = stats.get("charisma", 0)
	class_wisdom_bonus = stats.get("wisdom", 0)
	class_intelligence_bonus = stats.get("intelligence", 0)
	class_health_bonus = stats.get("base_health", 0)
	class_mana_bonus = stats.get("base_mana", 0)
	class_damage_bonus = stats.get("base_damage", 0)
	class_magic_damage_bonus = stats.get("base_magic_damage", 0)
	class_defense_bonus = stats.get("base_defense", 0)
	class_magic_defense_bonus = stats.get("base_magic_defense", 0)


func reset_current_stats() -> void:
	max_health = calculate_max_health()
	max_mana = calculate_max_mana()
	current_health = max_health
	current_mana = max_mana
	current_defense = calculate_total_defense()
	current_magic_defense = calculate_total_magic_defense()
	health_changed.emit(current_health, max_health)


func calculate_max_health() -> int:
	return max(base_health + class_health_bonus + buff_health_bonus + get_attribute_modifier(get_total_constitution()), 1)


func calculate_max_mana() -> int:
	var mana_attribute: int = max(get_total_intelligence(), get_total_wisdom())
	return max(base_mana + class_mana_bonus + buff_mana_bonus + get_attribute_modifier(mana_attribute), 0)


func calculate_total_damage() -> int:
	return max(base_damage + class_damage_bonus + equipment_damage_bonus + buff_damage_bonus + get_attribute_modifier(get_total_strength()), 0)


func calculate_total_magic_damage() -> int:
	return max(base_magic_damage + class_magic_damage_bonus + equipment_magic_damage_bonus + buff_magic_damage_bonus + get_attribute_modifier(get_total_intelligence()), 0)


func calculate_total_defense() -> int:
	return max(base_defense + class_defense_bonus + equipment_defense_bonus + buff_defense_bonus + get_attribute_modifier(get_total_dexterity()), 0)


func calculate_total_magic_defense() -> int:
	return max(base_magic_defense + class_magic_defense_bonus + equipment_magic_defense_bonus + buff_magic_defense_bonus + get_attribute_modifier(get_total_wisdom()), 0)


func take_damage(amount: int) -> int:
	if amount <= 0 or current_health <= 0:
		return 0

	var reduced_damage: int = max(amount - current_defense, 0)
	if reduced_damage <= 0:
		return 0

	current_health = max(current_health - reduced_damage, 0)
	health_changed.emit(current_health, max_health)
	damaged.emit(reduced_damage, current_health, max_health)

	if current_health <= 0:
		died.emit()

	return reduced_damage


func heal(amount: int) -> void:
	if amount <= 0:
		return

	current_health = min(current_health + amount, calculate_max_health())
	health_changed.emit(current_health, max_health)


func use_mana(amount: int) -> bool:
	if amount <= 0:
		return true

	if current_mana < amount:
		return false

	current_mana -= amount
	return true


func restore_mana(amount: int) -> void:
	if amount <= 0:
		return

	current_mana = min(current_mana + amount, calculate_max_mana())


func choose_class(new_class: int) -> void:
	player_class = new_class


func add_experience(amount: int) -> void:
	if amount <= 0 or is_max_level():
		return

	set_experience(experience + amount)


func set_experience(new_experience: int) -> void:
	experience = max(new_experience, 0)
	var previous_level: int = level
	level = get_level_for_experience(experience)

	if level != previous_level:
		level_changed.emit(level)

	experience_changed.emit(experience, level, get_experience_to_next_level())


func get_level_for_experience(total_experience: int) -> int:
	var resolved_level: int = 1
	for threshold_index in range(EXPERIENCE_BY_LEVEL.size()):
		if total_experience < EXPERIENCE_BY_LEVEL[threshold_index]:
			break

		resolved_level = threshold_index + 1

	return clampi(resolved_level, 1, EXPERIENCE_BY_LEVEL.size())


func get_experience_for_current_level() -> int:
	return EXPERIENCE_BY_LEVEL[level - 1]


func get_experience_for_next_level() -> int:
	if is_max_level():
		return -1

	return EXPERIENCE_BY_LEVEL[level]


func get_experience_to_next_level() -> int:
	var next_level_experience: int = get_experience_for_next_level()
	if next_level_experience < 0:
		return 0

	return max(next_level_experience - experience, 0)


func get_level_progress() -> float:
	if is_max_level():
		return 1.0

	var current_level_experience: int = get_experience_for_current_level()
	var next_level_experience: int = get_experience_for_next_level()
	var level_experience_range: int = max(next_level_experience - current_level_experience, 1)
	return clampf(float(experience - current_level_experience) / float(level_experience_range), 0.0, 1.0)


func get_proficiency_bonus() -> int:
	return PROFICIENCY_BY_LEVEL[level - 1]


func is_max_level() -> bool:
	return level >= EXPERIENCE_BY_LEVEL.size()


func reset_class_bonuses() -> void:
	class_strength_bonus = 0
	class_dexterity_bonus = 0
	class_constitution_bonus = 0
	class_charisma_bonus = 0
	class_wisdom_bonus = 0
	class_intelligence_bonus = 0
	class_health_bonus = 0
	class_mana_bonus = 0
	class_damage_bonus = 0
	class_magic_damage_bonus = 0
	class_defense_bonus = 0
	class_magic_defense_bonus = 0


func get_total_strength() -> int:
	return strength + class_strength_bonus


func get_total_dexterity() -> int:
	return dexterity + class_dexterity_bonus


func get_total_constitution() -> int:
	return constitution + class_constitution_bonus


func get_total_charisma() -> int:
	return charisma + class_charisma_bonus


func get_total_wisdom() -> int:
	return wisdom + class_wisdom_bonus


func get_total_intelligence() -> int:
	return intelligence + class_intelligence_bonus


func get_attribute_modifier(attribute_value: int) -> int:
	return floori((attribute_value - 10) / 2.0)


func recalculate_totals_keep_current() -> void:
	# Level up should update attributes/base stats before calling this.
	max_health = calculate_max_health()
	max_mana = calculate_max_mana()
	current_health = min(current_health, max_health)
	current_mana = min(current_mana, max_mana)
	current_defense = calculate_total_defense()
	current_magic_defense = calculate_total_magic_defense()
	health_changed.emit(current_health, max_health)
