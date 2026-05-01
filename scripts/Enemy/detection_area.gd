extends Area2D
class_name DetectionArea

@export var enemy: EnemyTemplate = null


func _ready() -> void:
	if enemy == null:
		enemy = get_parent() as EnemyTemplate

	var entered_callable: Callable = Callable(self, "on_body_entered")
	if not body_entered.is_connected(entered_callable):
		body_entered.connect(entered_callable)

	var exited_callable: Callable = Callable(self, "on_body_exited")
	if not body_exited.is_connected(exited_callable):
		body_exited.connect(exited_callable)


func on_body_entered(body: Player) -> void:
	if enemy == null:
		return

	enemy.player_ref = body
	
	
func on_body_exited(_body: Player) -> void:
	if enemy == null:
		return

	enemy.player_ref = null
