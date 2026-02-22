class_name Enemy extends CharacterBody3D

@export var moneda : PackedScene

var vida = 1
var gold = 1

signal change_live

func _ready() -> void:
	change_live.connect(update_hp)
	update_hp()
	
func update_hp() -> void:
	pass
	
func recibe_daño(d : int) -> void:
	if vida > 0:
		vida -= d
		if vida <= 0:
			die()
	update_hp()
	

func die() -> void:
	Progreso.p_gold += gold
	var moneda_i = moneda.instantiate()
	get_parent().add_child(moneda_i)
	moneda_i.global_position = self.global_position
	queue_free()
	
func set_vida(v :int) -> void:
	vida = v
	
func set_gold(g : int) -> void:
	gold = g
	
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		Progreso.p_gold += gold
		body.recibe_daño(vida)
		die()

func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	hide()

func _on_visible_on_screen_notifier_3d_screen_entered() -> void:
	show()
