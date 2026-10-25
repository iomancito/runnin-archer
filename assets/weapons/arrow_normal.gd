class_name Normal_Arrow extends CharacterBody3D

var player : Player
@export var speed : float
@export var distancia_max : float
@export var daño : int = 1
var posicion_inicial : float
#arco especial con el que se disparó ("" = original) y su nivel (ver Balance.ARCOS)
var arco : String = ""
var nivel : int = 0
#enemigos que aún puede atravesar (Thorn Bow) y los ya golpeados
var perfora : int = 0
var golpeados : Array = []

func inicia(p : Player) -> void:
	player = p
	speed = p.stats["f_velocidad"]
	distancia_max = p.stats["f_max_distancia"]
	posicion_inicial = global_position.z
	arco = p.stats.get("arco", "")
	nivel = p.stats.get("arco_nivel", 0)
	daño = max(1, roundi(p.stats["f_daño"] * Balance.arco_valor(arco, "daño", nivel)))
	perfora = int(Balance.arco_valor(arco, "perfora", nivel))

func _physics_process(delta: float) -> void:
	velocity.z = speed * delta
	move_and_slide()
	
func _process(delta: float) -> void:
	if global_position.z - posicion_inicial > distancia_max:
		queue_free()
		
func _on_area_3d_body_entered(body: Node3D) -> void:
	if not body is Enemy or body in golpeados:
		return
	#boss aún inmune (no ha empezado el combate): sin daño ni efectos
	if body is Boss and not body.combatiendo:
		queue_free()
		return
	golpeados.append(body)
	var d = daño
	if body is Boss:
		d = roundi(d * (1.0 + Balance.arco_valor(arco, "daño_boss", nivel)))
	#las habilidades se aplican antes del daño: el enemigo puede morir con este golpe
	_habilidades(body, d)
	body.recibe_daño(d)
	if perfora > 0:
		perfora -= 1
	else:
		queue_free()

func _habilidades(objetivo : Enemy, d : int) -> void:
	var v = func(clave): return Balance.arco_valor(arco, clave, nivel)
	match arco:
		"sunfire":
			var radio = v.call("explosion_radio")
			ArcoEfectos.explosion(get_parent(), objetivo.global_position, radio)
			for e in ArcoEfectos.enemigos_cerca(objetivo, radio, 99):
				e.recibe_daño(max(1, roundi(d * v.call("explosion_daño"))))
		"storm":
			var desde = objetivo.global_position
			for e in ArcoEfectos.enemigos_cerca(objetivo, v.call("cadena_radio"), int(v.call("cadena_saltos"))):
				ArcoEfectos.rayo(get_parent(), desde, e.global_position)
				desde = e.global_position
				e.recibe_daño(max(1, roundi(d * v.call("cadena_daño"))))
		"dragon":
			#explosión de fuego: daña y prende a los de alrededor (llega al carril de al lado)
			var radio = v.call("explosion_radio")
			var quemadura = d * v.call("quemadura_dps")
			ArcoEfectos.impacto_fuego(get_parent(), objetivo.global_position)
			ArcoEfectos.explosion(get_parent(), objetivo.global_position, radio)
			objetivo.quemar(quemadura, v.call("quemadura_seg"))
			for e in ArcoEfectos.enemigos_cerca(objetivo, radio, 99):
				e.quemar(quemadura, v.call("quemadura_seg"))
				e.recibe_daño(max(1, roundi(d * v.call("explosion_daño"))))
