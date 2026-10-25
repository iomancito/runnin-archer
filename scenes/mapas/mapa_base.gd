class_name Mapa extends Node3D

## Base de los mapas: decorado lateral (en MultiMesh), puertas de mejora, boss final
## y enemigos que aparecen poco a poco por delante del player según el plan de MapGenerator.

#estructuras laterales
@export var left : Array[PackedScene]
@export var right : Array[PackedScene]
#array enemigos
@export var enemies : Array[PackedScene]
#boss intermedio
@export var boss : Array[PackedScene]
#boss final
@export var final : PackedScene
#paneles
@export var panel : PackedScene
#spawn del player
@onready var spawn_point = $Suelo/Spawn

#metros por delante del player a los que aparecen los enemigos (la cámara dibuja hasta 40 m)
const ADELANTE : float = 80.0
#metros por detrás del player a los que se eliminan los enemigos que ya ha pasado
const DETRAS : float = 15.0
#enemigos creados como mucho por frame (repartir el coste de instanciar)
const SPAWNS_POR_FRAME : int = 2

#número de mapa (Niveles.MAPAS y multiplicadores de Balance); lo fija cada mapa
var numero : int = 1
#nombre que muestra la barra de vida del boss
var boss_name : String = "Boss"

var origen : float = 30
var plan : Array = []
var siguiente : int = 0
var vivos : Array[Node3D] = []
var jefe_final : Boss
var _revisa_detras : float = 0.0

func _ready() -> void:
	instancia_laterales()
	var cfg = Niveles.MAPAS[numero]
	plan = MapGenerator.generar(cfg, Balance.dif().densidad, Balance.dif().hordas)
	instancia_paneles(cfg.puertas)
	jefe_final = final.instantiate()
	jefe_final.name = "boss_final"
	$Suelo/Enemigos.add_child(jefe_final)
	jefe_final.global_position.z = cfg.largo
	jefe_final.setup_boss(numero)
	#los primeros enemigos se crean ya, durante la pantalla de carga
	_spawn_hasta(get_spawn_point().z + ADELANTE, plan.size())

func get_spawn_point() -> Vector3:
	return spawn_point.global_position

func get_boss() -> Enemy:
	return jefe_final

func set_boss(main : Node) -> void:
	jefe_final.connect("muere_boss", main.muere_boss)

func instancia_laterales() -> void:
	for i in range (0,100):
		var instancia_R = right[randi_range(0, right.size() - 1)].instantiate()
		var instancia_L = left[randi_range(0, left.size() - 1)].instantiate()
		$Suelo/Laterales.add_child(instancia_R)
		instancia_R.global_position = Vector3(0,0,i*origen)
		$Suelo/Laterales.add_child(instancia_L)
		instancia_L.global_position = Vector3(0,0,i*origen)
	#miles de mallas repetidas -> pocos MultiMesh por bloque (rendimiento en móvil)
	MeshBatcher.batch($Suelo/Laterales, origen)

func instancia_paneles(posiciones : Array) -> void:
	for z in posiciones:
		var instancia = panel.instantiate()
		$Suelo/Paneles.add_child(instancia)
		instancia.global_position.z = z

#escena de cada tipo de enemigo del plan; cada mapa la define
func escena_de(_tipo : String) -> PackedScene:
	return enemies[0]

#ajustes extra tras crear un enemigo (p.ej. escalar el zombi grande)
func prepara(_enemigo : Enemy, _tipo : String) -> void:
	pass

func _physics_process(delta: float) -> void:
	if not is_instance_valid(Progreso.player):
		return
	var pz = Progreso.player.global_position.z
	_spawn_hasta(pz + ADELANTE, SPAWNS_POR_FRAME)
	#los enemigos ya superados se eliminan (sin dar oro)
	_revisa_detras -= delta
	if _revisa_detras <= 0.0:
		_revisa_detras = 0.5
		for e in vivos:
			if is_instance_valid(e) and e.global_position.z < pz - DETRAS:
				e.queue_free()
		vivos = vivos.filter(func(e): return is_instance_valid(e) and not e.is_queued_for_deletion())

func _spawn_hasta(z_max : float, limite : int) -> void:
	var creados = 0
	while siguiente < plan.size() and plan[siguiente].z <= z_max and creados < limite:
		var s = plan[siguiente]
		siguiente += 1
		creados += 1
		var e : Enemy = escena_de(s.tipo).instantiate()
		e.name = "%s_%d" % [s.tipo, siguiente]
		$Suelo/Enemigos.add_child(e)
		e.global_position = Vector3(s.x, 0, s.z)
		e.setup(s.tipo, s.z, numero, s.horda)
		prepara(e, s.tipo)
		vivos.append(e)

#crea uno de cada tipo delante de la cámara para compilar sus shaders durante la carga
func precalentar() -> void:
	var z = get_spawn_point().z + 6.0
	var x = -4.0
	var tipos = Niveles.MAPAS[numero].tipos.keys()
	tipos.append(Niveles.MAPAS[numero].jefes.tipo)
	for tipo in tipos:
		var e : Enemy = escena_de(tipo).instantiate()
		$Suelo/Enemigos.add_child(e)
		e.global_position = Vector3(x, 0, z)
		e.setup(tipo, 0, numero)
		prepara(e, tipo)
		x += 2.5
	var b = final.instantiate()
	$Suelo/Enemigos.add_child(b)
	b.global_position = Vector3(0, 0, z + 8.0)
	var p = panel.instantiate()
	$Suelo/Paneles.add_child(p)
	p.global_position.z = z + 3.0
	var muestra : Enemy = enemies[0].instantiate()
	var moneda = muestra.moneda.instantiate()
	muestra.free()
	add_child(moneda)
	moneda.global_position = Vector3(4, 0, z)
	#efectos del arco equipado (los de otro arco se precalientan al comprarlo en la tienda)
	ArcoEfectos.precalentar(Progreso.arco, self, Vector3(0, 0, z + 2.0))
	#números flotantes (+oro, -daño) y de vida: sus glifos se rasterizan la primera vez
	for tam in [[96, 24], [110, 26], [100, 30]]:
		var l = Label3D.new()
		l.text = "+-0123456789"
		l.font_size = tam[0]
		l.outline_size = tam[1]
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		add_child(l)
		l.global_position = Vector3(0, 1.5, z)
