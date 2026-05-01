extends EnemyTexture
class_name WhaleTexture

@onready var collision_area: CollisionArea = get_node_or_null("../CollisionArea") as CollisionArea

func animate(velocity: Vector2) -> void:
	if enemy == null or animation == null:
		return

	if enemy.can_hit or enemy.can_die or enemy.can_attack:
		action_behavior()
	else:
		move_behavior(velocity)
		
		
func action_behavior() -> void:
	if enemy.can_die:
		set_attack_hitbox_enabled(false)
		play_action("dead")
		enemy.can_hit = false
		enemy.can_attack = false
		
	elif enemy.can_hit:
		set_attack_hitbox_enabled(false)
		play_action("hit")
		enemy.can_attack = false
		
	elif enemy.can_attack:
		set_attack_hitbox_enabled(true)
		play_action("attack")
		
		
func move_behavior(velocity: Vector2) -> void:
	set_attack_hitbox_enabled(false)
	if velocity.x != 0:
		play_action("run")
	else:
		play_action("idle")
		
		
func on_animation_finished(anim_name: String) -> void:
	if enemy == null:
		return

	match anim_name:
		"hit":
			set_attack_hitbox_enabled(false)
			enemy.can_hit = false
			if collision_area != null and collision_area.health <= 0:
				enemy.can_die = true
				play_action("dead")
			else:
				enemy.set_physics_process(true)
			
		"dead":
			set_attack_hitbox_enabled(false)
			enemy.kill_enemy()
			
		"kill":
			set_attack_hitbox_enabled(false)
			enemy.queue_free()
			
		"attack":
			set_attack_hitbox_enabled(false)
			enemy.can_attack = false


func play_action(animation_name: String) -> void:
	if not animation.has_animation(animation_name):
		return

	if animation.current_animation == animation_name and animation.is_playing():
		return

	animation.play(animation_name)


func play_hit_reaction() -> void:
	set_attack_hitbox_enabled(false)
	play_action("hit")
	enemy.can_attack = false


func set_attack_hitbox_enabled(is_enabled: bool) -> void:
	if attack_area_collision == null:
		return

	attack_area_collision.disabled = not is_enabled
