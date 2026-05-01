extends Node2D

@export var player_path: NodePath = ^"Player"
@export_file("*.tscn") var game_over_scene_path: String = ""

@onready var player: Player = get_node_or_null(player_path) as Player
@onready var player_animations: PlayerAnimations = _get_player_animations()


func _ready() -> void:
	if player_animations != null:
		var game_over_callable: Callable = Callable(self, "_on_game_over")
		if not player_animations.game_over.is_connected(game_over_callable):
			player_animations.game_over.connect(game_over_callable)


func _process(delta: float) -> void:
	pass


func _get_player_animations() -> PlayerAnimations:
	if player == null:
		return null

	return player.get_node_or_null("AnimatedSprite2D") as PlayerAnimations


func _on_game_over() -> void:
	if game_over_scene_path != "":
		get_tree().change_scene_to_file(game_over_scene_path)
	else:
		get_tree().reload_current_scene()
