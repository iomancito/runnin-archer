class_name Boss extends Enemy

## Boss final de cada mapa: para al player al tocarlo y le ataca hasta que uno de los dos muere.
## Cada ataque es una animación del modelo y, en el momento en que abre la boca, proyectiles que
## marcan el suelo donde caerán (ver Proyectil). La secuencia de ataques está en
## Niveles.MAPAS[n].boss_ataques y lo difícil que es esquivarlos, en Balance.BOSS_ATAQUES.
## Cada dragón (subclase) dice en _init qué animación usa para cada ataque y dónde tiene la boca.

signal muere_boss(s : Node3D)

#animación de cada tipo de ataque: [nombre, segundo en el que sale el fuego]
var anim_ataques : Dictionary = {}
var anim_reposo : String = "idle"
var anim_muerte : String = "death"
#segundos de la animación de muerte antes de pasar a la pantalla de resultados
var tiempo_muerte : float = 1.8
#boca: hueso de la cabeza y metros por delante de él
var hueso_boca : String = ""
var boca_adelante : float = 1.0
var estilo : int = Proyectil.Estilo.FUEGO
#tamaño de las bolas respecto al efecto original
var escala_bola : float = 1.2

var daño_ataque : int = 3
var intervalo : float = 2.5
var boss_gold : int = 100
var combatiendo : bool = false
var _espera : float = 0.0
var _atacando : bool = false
var _n_ataque : int = 0
var _anim : AnimationPlayer
var _esqueleto : Skeleton3D
var _hueso : int = -1

#alturas de la trayectoria de cada ataque (m sobre la línea recta)
const ARCO_BOLA : float = 2.0
const ARCO_BARRERA : float = 0.8
const ARCO_LLUVIA : float = 9.0
const CARRIL_MEDIO_ANCHO : float = 1.0

func _ready() -> void:
	super()
	_anim = find_child("AnimationPlayer", true, false)
	_esqueleto = find_child("Skeleton3D", true, false)
	if _esqueleto and hueso_boca != "":
		_hueso = _esqueleto.find_bone(hueso_boca)
	if _anim:
		if _anim.has_animation(anim_reposo):
			_anim.get_animation(anim_reposo).loop_mode = Animation.LOOP_LINEAR
		_anim.animation_finished.connect(_fin_animacion)
		_reposo()

func setup_boss(m : int) -> void:
	mapa = m
	add_to_group(ArcoEfectos.GRUPO_ENEMIGOS)
	set_vida(Balance.boss_vida(m))
	daño_ataque = Balance.boss_daño(m)
	intervalo = Balance.boss_intervalo()
	boss_gold = Balance.boss_oro(m)
	update_hp()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player and not combatiendo and vida > 0:
		body.stats["p_speed"] = 0
		combatiendo = true
		#el primer ataque llega tras medio intervalo: lo justo para ver al dragón
		_espera = intervalo * 0.5

func _physics_process(delta: float) -> void:
	if not combatiendo or _atacando or vida <= 0 or not is_instance_valid(Progreso.player):
		return
	_espera -= delta
	if _espera <= 0.0:
		ataca()

func ataca() -> void:
	var player = Progreso.player
	if player.is_dead:
		return
	var secuencia : Array = Niveles.MAPAS[mapa].get("boss_ataques", ["bola"])
	var tipo : String = secuencia[_n_ataque % secuencia.size()]
	_n_ataque += 1
	_atacando = true
	var datos = anim_ataques.get(tipo, [anim_reposo, 0.3])
	if _anim and _anim.has_animation(datos[0]):
		_anim.play(datos[0], 0.2)
	await get_tree().create_timer(datos[1], false).timeout
	if vida > 0 and combatiendo and is_instance_valid(player) and not player.is_dead:
		var cfg = Balance.boss_ataque()
		match tipo:
			"barrera":
				_barrera(cfg)
			"lluvia":
				await _lluvia(cfg)
			_:
				await _rafaga(cfg)
	_atacando = false
	_espera = intervalo

#bolas seguidas a donde está el player (o a donde estará si sigue moviéndose)
func _rafaga(cfg : Dictionary) -> void:
	for i in cfg.rafaga:
		if vida <= 0 or not combatiendo or not is_instance_valid(Progreso.player):
			return
		var p = Progreso.player
		var x = p.global_position.x + p.velocity.x * cfg.aviso * cfg.prediccion
		x = clampf(x, MapGenerator.CARRILES[0], MapGenerator.CARRILES[-1])
		Proyectil.lanzar(get_parent(), boca(), Vector3(x, 0, p.global_position.z), cfg.aviso, daño_ataque,
			estilo, Proyectil.Forma.CIRCULO, Balance.BOSS_BOLA_RADIO, ARCO_BOLA, escala_bola)
		if i < cfg.rafaga - 1:
			await get_tree().create_timer(Balance.BOSS_RAFAGA_CADENCIA, false).timeout

#fuego en todos los carriles menos los libres; uno de ellos está al lado del player
func _barrera(cfg : Dictionary) -> void:
	var libres = _carriles_libres(_carril_de(Progreso.player.global_position.x), cfg.libres)
	_fuego_carriles(libres, cfg.aviso * Balance.BOSS_AVISO_CARRILES, ARCO_BARRERA)

#oleadas de fuego que sube y cae del cielo; el carril libre se mueve uno cada oleada
func _lluvia(cfg : Dictionary) -> void:
	var libre = _carril_de(Progreso.player.global_position.x)
	for i in cfg.oleadas:
		if vida <= 0 or not combatiendo or not is_instance_valid(Progreso.player):
			return
		var libres = _carriles_libres(libre, cfg.libres)
		libre = libres[0]
		var aviso = cfg.aviso * Balance.BOSS_AVISO_CARRILES
		_fuego_carriles(libres, aviso, ARCO_LLUVIA)
		if i < cfg.oleadas - 1:
			await get_tree().create_timer(aviso + Balance.BOSS_OLEADAS_PAUSA, false).timeout

func _fuego_carriles(libres : Array, aviso : float, alto_arco : float) -> void:
	var z = Progreso.player.global_position.z
	for c in MapGenerator.CARRILES.size():
		if c in libres:
			continue
		Proyectil.lanzar(get_parent(), boca(), Vector3(MapGenerator.CARRILES[c], 0, z), aviso, daño_ataque,
			estilo, Proyectil.Forma.CARRIL, CARRIL_MEDIO_ANCHO, alto_arco, escala_bola)

#carril (índice) más cercano a x
func _carril_de(x : float) -> int:
	var mejor = 0
	for c in MapGenerator.CARRILES.size():
		if abs(MapGenerator.CARRILES[c] - x) < abs(MapGenerator.CARRILES[mejor] - x):
			mejor = c
	return mejor

#"cuantos" carriles libres; el primero, junto al carril "desde" (a un cambio de carril)
func _carriles_libres(desde : int, cuantos : int) -> Array:
	var vecinos = [desde - 1, desde + 1].filter(func(c): return c >= 0 and c < MapGenerator.CARRILES.size())
	var libres = [vecinos.pick_random()]
	var resto = range(MapGenerator.CARRILES.size()).filter(func(c): return not c in libres)
	resto.shuffle()
	for c in resto.slice(0, cuantos - 1):
		libres.append(c)
	return libres

#posición de la boca ahora mismo (sin esqueleto, a media altura delante del boss)
func boca() -> Vector3:
	if _esqueleto and _hueso >= 0:
		var cabeza = _esqueleto.global_transform * _esqueleto.get_bone_global_pose(_hueso)
		return cabeza.origin + global_basis.z.normalized() * -boca_adelante
	return global_position + Vector3(0, 3.0, -2.0)

func _reposo() -> void:
	if _anim and _anim.has_animation(anim_reposo):
		_anim.play(anim_reposo, 0.3)

func _fin_animacion(nombre : StringName) -> void:
	if nombre != anim_muerte and vida > 0:
		_reposo()

func die() -> void:
	combatiendo = false
	recompensa(boss_gold)
	#lo que queda en el aire desaparece: el combate ha terminado
	get_tree().call_group(Proyectil.GRUPO, "cancelar")
	if _anim and _anim.has_animation(anim_muerte):
		_anim.play(anim_muerte, 0.2)
		await get_tree().create_timer(tiempo_muerte, false).timeout
	muere_boss.emit(self)
