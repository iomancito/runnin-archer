class_name Enemy extends CharacterBody3D

@export var moneda : PackedScene

var vida = 1
var vida_max = 1
var gold = 1
var daño_contacto = 1 #daño al chocar con el player
var mapa : int = 1

#colores del número de vida según lo difícil que es matarlo
const COLOR_FACIL = Color(0.55, 1.0, 0.45)
const COLOR_MEDIO = Color(1.0, 0.85, 0.3)
const COLOR_DIFICIL = Color(1.0, 0.3, 0.25)

signal change_live

func _ready() -> void:
	change_live.connect(update_hp)
	update_hp()

#vida, daño y oro según el tipo de enemigo, la distancia recorrida y el mapa (ver Balance)
func setup(tipo : String, z : float, m : int) -> void:
	mapa = m
	set_vida(Balance.vida_enemigo(tipo, z, m))
	daño_contacto = Balance.daño_enemigo(tipo, m)
	gold = Balance.oro_enemigo(tipo, m)
	update_hp()

func update_hp() -> void:
	if not has_node("Label3D"):
		return
	$Label3D.text = str(vida)
	$Label3D.modulate = threat_color()

#daño que el player le hace antes de chocar -> verde (lo mata) / amarillo (casi) / rojo (esquivar)
func threat_color() -> Color:
	var stats = Progreso.player.stats if is_instance_valid(Progreso.player) else Progreso.progreso_permanente
	var ventana = stats["f_max_distancia"] / max(stats["p_speed"] / 60.0, 0.1)
	var daño = ventana * stats["p_attack_speed"] * stats["f_daño"] * stats["f_cantidad"]
	if daño >= vida:
		return COLOR_FACIL
	elif daño * 2.0 >= vida:
		return COLOR_MEDIO
	return COLOR_DIFICIL

func recibe_daño(d : int) -> void:
	if vida > 0:
		vida -= d
		if vida <= 0:
			die()
	update_hp()


func die() -> void:
	recompensa()
	var moneda_i = moneda.instantiate()
	get_parent().add_child(moneda_i)
	moneda_i.global_position = self.global_position
	queue_free()

#da el oro de la muerte y cuenta la baja (gold = 0 si murió chocando con el player)
func recompensa(cantidad : int = gold) -> void:
	if cantidad <= 0:
		return
	cantidad = Progreso.oro_con_bonus(cantidad)
	Progreso.p_gold += cantidad
	Progreso.run_gold += cantidad
	Progreso.run_kills += 1
	popup_texto("+%d" % cantidad, Color(1.0, 0.84, 0.3))

#texto flotante que sube y se desvanece
func popup_texto(texto : String, color : Color) -> void:
	var label = Label3D.new()
	label.text = texto
	label.modulate = color
	label.outline_modulate = Color(0.1, 0.06, 0.02)
	label.font_size = 96
	label.outline_size = 24
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	get_parent().add_child(label)
	label.global_position = global_position + Vector3.UP * 1.5
	var tw = label.create_tween().set_parallel()
	tw.tween_property(label, "global_position:y", label.global_position.y + 1.5, 0.8).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.chain().tween_callback(label.queue_free)

func set_vida(v :int) -> void:
	vida = v
	vida_max = v

func set_gold(g : int) -> void:
	gold = g

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		body.recibe_daño(daño_contacto)
		#chocar con el enemigo no da oro
		gold = 0
		die()

func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	hide()

func _on_visible_on_screen_notifier_3d_screen_entered() -> void:
	show()
	update_hp()
