class_name DragonRojo extends Enemy

signal muere_boss(s :Node3D)

func update_hp() -> void:
	$Label3D.text = str(vida)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		body.stats["p_speed"] = 0

func die() -> void:
	print("muere dragon negro")
	muere_boss.emit(self)
