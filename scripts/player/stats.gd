extends Node
class_name PlayerStats

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

@export_group("Class")
@export_enum("None", "Warrior", "Mage", "Rogue", "Cleric") var player_class: int = PlayerClass.NONE:
	set(value):
		player_class = value
		if is_node_ready():
			apply_class_stats()
			reset_current_stats()

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


func take_damage(amount: int) -> void:
	if amount <= 0:
		return

	var reduced_damage: int = max(amount - current_defense, 0)
	current_health = max(current_health - reduced_damage, 0)


func heal(amount: int) -> void:
	if amount <= 0:
		return

	current_health = min(current_health + amount, calculate_max_health())


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
