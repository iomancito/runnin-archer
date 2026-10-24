class_name PanelSkills extends Node3D

#dos mejoras distintas al azar de Balance.PUERTAS (texto, stat, incremento)
var left_rnd : int
var right_rnd : int
@onready var left_txt = $left_mesh/left_label
@onready var right_txt = $right_mesh/right_label

func _ready() -> void:
	var n = Balance.PUERTAS.size()
	left_rnd = randi_range(0, n - 1)
	right_rnd = randi_range(0, n - 1)
	while left_rnd == right_rnd:
		right_rnd = randi_range(0, n - 1)
	left_txt.text = Balance.PUERTAS[left_rnd][0]
	right_txt.text = Balance.PUERTAS[right_rnd][0]

func _on_left_area_body_entered(body: Node3D) -> void:
	if body is Player:
		upgrade_skill_player(body, left_rnd)
		
func _on_right_area_body_entered(body: Node3D) -> void:
	if body is Player:
		upgrade_skill_player(body, right_rnd)

func upgrade_skill_player(body : Node3D, valor : int) -> void:
	body.mejora(Balance.PUERTAS[valor][1], Balance.PUERTAS[valor][2])
	queue_free()
