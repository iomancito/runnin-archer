class_name Boss extends Enemy

## Boss final de cada mapa: para al player al tocarlo y le ataca cada cierto tiempo
## hasta que uno de los dos muere.

signal muere_boss(s : Node3D)

var daño_ataque : int = 3
var intervalo : float = 2.5
var boss_gold : int = 100
var combatiendo : bool = false
var _espera : float = 0.0

func setup_boss(m : int) -> void:
	mapa = m
	set_vida(Balance.boss_vida(m))
	daño_ataque = Balance.boss_daño(m)
	intervalo = Balance.boss_intervalo()
	boss_gold = Balance.boss_oro(m)
	update_hp()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		body.stats["p_speed"] = 0
		combatiendo = true
		#el primer ataque llega tras un intervalo completo
		_espera = intervalo

func _physics_process(delta: float) -> void:
	if not combatiendo or vida <= 0 or not is_instance_valid(Progreso.player):
		return
	_espera -= delta
	if _espera <= 0.0:
		_espera = intervalo
		ataca(Progreso.player)

func ataca(player : Node3D) -> void:
	if player.is_dead:
		return
	player.recibe_daño(daño_ataque)
	#texto rojo sobre el player
	var label = Label3D.new()
	label.text = "-%d" % daño_ataque
	label.modulate = Color(1, 0.3, 0.25)
	label.outline_modulate = Color(0.1, 0.02, 0.02)
	label.font_size = 110
	label.outline_size = 26
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	get_parent().add_child(label)
	label.global_position = player.global_position + Vector3.UP * 2.0
	var tw = label.create_tween().set_parallel()
	tw.tween_property(label, "global_position:y", label.global_position.y + 1.2, 0.7)
	tw.tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tw.chain().tween_callback(label.queue_free)

func die() -> void:
	combatiendo = false
	recompensa(boss_gold)
	muere_boss.emit(self)
