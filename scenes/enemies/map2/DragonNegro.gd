class_name DragonNegro extends Enemy

signal muere_boss(s :Node3D)

@export var boss_gold : int = 100

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		body.stats["p_speed"] = 0

func die() -> void:
	print("muere dragon negro")
	recompensa(boss_gold)
	muere_boss.emit(self)
