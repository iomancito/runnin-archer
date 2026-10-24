class_name ArcoEfectos

## Efectos visuales y búsquedas de las habilidades de los arcos especiales.
## Efectos de BinbunVFX Vol.2 (CC0, assets/BinbunVFX_Vol2) reutilizados en un pool para no
## instanciar partículas en cada flecha, y sin sus luces (cada luz dinámica cuesta en el móvil).
## Mapa.precalentar los muestra una vez durante la carga para compilar sus shaders.

const GRUPO_ENEMIGOS : StringName = &"enemigos"

#cargados por código: también están en export_files del preset Android
const VFX_EXPLOSION : PackedScene = preload("res://assets/BinbunVFX_Vol2/ExplosionFX/effects/ground/vfx_ground_explosion_01.tscn")
const VFX_RAYO : PackedScene = preload("res://assets/BinbunVFX_Vol2/ElectricFX/effects/zap/vfx_zap_lightning_01.tscn")
const VFX_IMPACTO_FUEGO : PackedScene = preload("res://assets/BinbunVFX_Vol2/ElementalMagicFX/effects/cast/vfx_fire_cast_01.tscn")
const VFX_QUEMADURA : PackedScene = preload("res://assets/BinbunVFX_Vol2/ElementalMagicFX/effects/area/vfx_fire_area_01.tscn")

#instancias por tipo de efecto puntual; si se piden más se reutiliza la más antigua
const TAM_POOL : int = 6
#enemigos ardiendo con efecto visual a la vez (el daño se aplica igualmente a todos)
const MAX_QUEMADURAS_VISIBLES : int = 8
#escala de cada efecto respecto a su tamaño original
const ESCALA_EXPLOSION : float = 0.2 #por metro de radio
#el humo original es gris oscuro y dura 2 s: tapa a los enemigos, se aclara y se acelera
const COLOR_HUMO_EXPLOSION : Color = Color(0.95, 0.5, 0.15)
const VELOCIDAD_EXPLOSION : float = 1.6
const ESCALA_RAYO : float = 0.6
const ESCALA_IMPACTO_FUEGO : float = 0.5
const ESCALA_QUEMADURA : float = 0.35

static var _pools := {}
static var _quemaduras_activas : int = 0
static var _barra : BoxMesh

#muestra una vez los efectos de un arco para compilar sus shaders antes de usarlo en partida
#(sus partículas tardan ~1-2 s en compilarse en el móvil la primera vez)
static func precalentar(id : String, padre : Node3D, pos : Vector3) -> void:
	match id:
		"sunfire":
			explosion(padre, pos, 1.5)
		"storm":
			rayo(padre, pos + Vector3(-2, 0, 0), pos)
		"dragon":
			impacto_fuego(padre, pos)
			var fuego = empieza_quemadura(padre)
			if fuego:
				fuego.global_position = pos + Vector3(2, 0, 0)

#enemigos vivos más cercanos a "origen" dentro del radio (en el plano xz), sin contarlo a él
static func enemigos_cerca(origen : Node3D, radio : float, maximo : int) -> Array:
	var lista = []
	for e in origen.get_tree().get_nodes_in_group(GRUPO_ENEMIGOS):
		if e == origen or not is_instance_valid(e) or e.vida <= 0:
			continue
		var d = Vector2(e.global_position.x - origen.global_position.x, e.global_position.z - origen.global_position.z).length()
		if d <= radio:
			lista.append([d, e])
	lista.sort_custom(func(a, b): return a[0] < b[0])
	return lista.slice(0, maximo).map(func(par): return par[1])

#Sunfire Bow: explosión en el punto de impacto
static func explosion(padre : Node, pos : Vector3, radio : float) -> void:
	_lanza(VFX_EXPLOSION, padre, pos, ESCALA_EXPLOSION * radio)

#Storm Bow: rayo que cae sobre cada enemigo de la cadena y línea que muestra el salto
static func rayo(padre : Node, desde : Vector3, hasta : Vector3) -> void:
	_lanza(VFX_RAYO, padre, hasta, ESCALA_RAYO)
	_linea(padre, desde, hasta)

#Dragonbone Bow: llamarada al impactar
static func impacto_fuego(padre : Node, pos : Vector3) -> void:
	_lanza(VFX_IMPACTO_FUEGO, padre, pos + Vector3.UP * 0.8, ESCALA_IMPACTO_FUEGO)

#Dragonbone Bow: fuego bajo un enemigo mientras arde; devuelve el efecto (o null si hay demasiados)
static func empieza_quemadura(enemigo : Node3D) -> Node3D:
	if _quemaduras_activas >= MAX_QUEMADURAS_VISIBLES:
		return null
	_quemaduras_activas += 1
	var fx = _prepara(VFX_QUEMADURA.instantiate())
	enemigo.add_child(fx)
	fx.scale = Vector3.ONE * ESCALA_QUEMADURA
	#si el enemigo muere con el fuego encendido, el efecto se libera con él
	fx.tree_exiting.connect(func(): _quemaduras_activas -= 1)
	return fx

static func termina_quemadura(fx : Node3D) -> void:
	if not is_instance_valid(fx):
		return
	fx.emitting = false
	#deja que se apaguen las partículas antes de liberarlo
	fx.get_tree().create_timer(1.0, false).timeout.connect(func(): if is_instance_valid(fx): fx.queue_free())

#efecto puntual del pool: se recoloca y se reproduce desde el principio
static func _lanza(escena : PackedScene, padre : Node, pos : Vector3, escala : float) -> void:
	var pool : Array = _pools.get_or_add(escena, [])
	pool = pool.filter(func(fx): return is_instance_valid(fx))
	var fx : Node3D
	if pool.size() < TAM_POOL:
		fx = _prepara(escena.instantiate())
		fx.set("one_shot", true)
		padre.add_child(fx)
		if escena == VFX_EXPLOSION:
			fx.tertiary_color = COLOR_HUMO_EXPLOSION
			fx.speed_scale = VELOCIDAD_EXPLOSION
	else:
		#el más antiguo pasa al final de la lista
		fx = pool.pop_front()
		if fx.get_parent() != padre:
			fx.reparent(padre, false)
	pool.append(fx)
	_pools[escena] = pool
	fx.global_position = pos
	fx.scale = Vector3.ONE * escala
	fx.play()

#sin reproducción automática y sin luces dinámicas
static func _prepara(fx : Node3D) -> Node3D:
	fx.set("autoplay", false)
	for luz in fx.find_children("*", "Light3D", true, false):
		luz.visible = false
	return fx

#línea azul entre dos puntos que se desvanece
static func _linea(padre : Node, desde : Vector3, hasta : Vector3) -> void:
	if _barra == null:
		_barra = BoxMesh.new()
		_barra.size = Vector3(0.1, 0.1, 1.0)
		var m = StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(0.45, 0.85, 1.0, 0.9)
		_barra.material = m
	var a = desde + Vector3.UP
	var b = hasta + Vector3.UP
	if a.distance_to(b) < 0.05:
		return
	var mi = MeshInstance3D.new()
	mi.mesh = _barra
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(mi)
	mi.global_position = (a + b) * 0.5
	mi.look_at(b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.FORWARD)
	mi.scale = Vector3(1, 1, a.distance_to(b))
	var tw = mi.create_tween()
	tw.tween_property(mi, "transparency", 1.0, 0.25)
	tw.tween_callback(mi.queue_free)
