class_name Ogro extends Enemy

@export var panel : PackedScene = load("res://scenes/pickups/panel/panel.tscn")

func _ready() -> void:
	gold = 5
	
func die() -> void:
	recompensa()
	var moneda_i = moneda.instantiate()
	get_parent().add_child(moneda_i)
	moneda_i.global_position = self.global_position
	var panel_i = panel.instantiate()
	get_parent().add_child(panel_i)
	panel_i.global_position = self.global_position
	panel_i.global_position = Vector3(0, 0, self.global_position.z + 10)
	queue_free()
	

func _process(delta: float) -> void:
	if not is_instance_valid(Progreso.player):
		return
	$mesh.look_at(Progreso.player.global_position, Vector3(0, 1, 0))
	
func _on_area_3d_2_body_entered(body: Node3D) -> void:
	if body is Player:
		$AnimationPlayer.play("golpear")
