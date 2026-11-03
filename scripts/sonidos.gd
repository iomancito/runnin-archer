extends Node
## Autoload Sonidos: efectos de sonido en el bus Effects (su volumen lo pone Ajustes).
##
## Los WAV de assets/sonidos/ se generan con tools/generar_sonidos.py. Cada efecto tiene un
## AudioStreamPlayer propio con varias voces (max_polyphony) y un AudioStreamRandomizer que elige
## variante y varía el tono, así los sonidos repetidos (disparo, impacto...) no cansan.
## Sin posición 3D: la cámara va pegada al player y suena todo igual de cerca (y es más barato).
##
## Los efectos de partida solo suenan con en_partida = true (lo pone Main): así no suenan los
## precalentados de la carga ni de la tienda. Los de interfaz suenan siempre, también en pausa.

const CARPETA : String = "res://assets/sonidos/"
const BUS : String = "Effects"

#nombre -> variantes (archivos sin .wav), volumen (dB), variación de tono (1 = ninguna),
#voces a la vez y segundos mínimos entre dos (para disparos, impactos y bajas en hordas).
#Los WAV salen con la misma sonoridad en un altavoz de móvil (~-14 dB, ver generar_sonidos.py) y la
#música da ~-25: los clics quedan a ~-17 (por encima de la música, si no se pierden), los sonidos
#constantes (disparo, moneda) a ~-22/-24 y los grandes momentos (rugidos, muerte) a ~-14
const EFECTOS : Dictionary = {
	#partida
	"disparo": {"archivos": ["disparo_1", "disparo_2", "disparo_3"], "db": -8.0, "tono": 1.08, "voces": 3, "intervalo": 0.06},
	"impacto": {"archivos": ["impacto_1", "impacto_2", "impacto_3"], "db": -3.0, "tono": 1.12, "voces": 4, "intervalo": 0.04},
	"muerte": {"archivos": ["muerte_1", "muerte_2"], "db": -3.5, "tono": 1.15, "voces": 3, "intervalo": 0.06},
	"moneda": {"archivos": ["moneda"], "db": -10.0, "tono": 1.06, "voces": 3, "intervalo": 0.07},
	"puerta": {"archivos": ["puerta"], "db": -1.0},
	"herido": {"archivos": ["herido"], "db": 0.0, "tono": 1.08, "voces": 2, "intervalo": 0.1},
	"muerte_jugador": {"archivos": ["muerte_jugador"], "db": 0.0},
	"explosion": {"archivos": ["explosion_1", "explosion_2"], "db": -1.0, "tono": 1.1, "voces": 3, "intervalo": 0.08},
	"rayo": {"archivos": ["rayo"], "db": -7.0, "tono": 1.15, "voces": 3, "intervalo": 0.07},
	"bola_fuego": {"archivos": ["bola_fuego"], "db": 0.0, "tono": 1.1, "voces": 3, "intervalo": 0.1},
	"magia": {"archivos": ["magia"], "db": -6.0, "tono": 1.1, "voces": 2, "intervalo": 0.1},
	"acido": {"archivos": ["acido"], "db": -6.0, "tono": 1.1, "voces": 2, "intervalo": 0.1},
	"salpicadura": {"archivos": ["salpicadura"], "db": -6.0, "tono": 1.1, "voces": 2, "intervalo": 0.1},
	"piedra": {"archivos": ["piedra"], "db": -6.0, "tono": 1.1, "voces": 2, "intervalo": 0.1},
	"golpe_piedra": {"archivos": ["golpe_piedra"], "db": -1.0, "tono": 1.1, "voces": 2, "intervalo": 0.1},
	"impacto_magia": {"archivos": ["impacto_magia"], "db": -5.0, "tono": 1.1, "voces": 3, "intervalo": 0.08},
	"rugido": {"archivos": ["rugido"], "db": 0.0, "tono": 1.05},
	"muerte_boss": {"archivos": ["muerte_boss"], "db": 0.0},
	#interfaz
	"click": {"archivos": ["click"], "db": -2.5, "tono": 1.05, "voces": 2, "intervalo": 0.05, "interfaz": true},
	"atras": {"archivos": ["atras"], "db": -3.0, "interfaz": true},
	"compra": {"archivos": ["compra"], "db": -2.0, "interfaz": true},
	"error": {"archivos": ["error"], "db": -1.0, "interfaz": true},
	"logro": {"archivos": ["logro"], "db": -1.0, "interfaz": true},
}

#sonidos de los proyectiles enemigos por estilo (Proyectil.Estilo): [lanzar, impacto]
const PROYECTILES : Dictionary = {
	0: ["bola_fuego", "explosion"],    #FUEGO: dragón rojo, crías
	1: ["bola_fuego", "explosion"],    #FUEGO_OSCURO: dragón negro
	2: ["magia", "impacto_magia"],     #ALMAS: dragón esqueleto
	3: ["magia", "impacto_magia"],     #MAGIA: esqueleto mago
	4: ["acido", "salpicadura"],       #ACIDO: zombi escupidor
	5: ["piedra", "golpe_piedra"],     #PIEDRA: troll
}

#botones con sonido propio en vez del clic (por nombre de nodo)
const BOTONES_ATRAS : Array[String] = ["BackButton"]

var en_partida : bool = false
var _reproductores : Dictionary = {}
#último momento (ms) en que sonó cada efecto
var _ultimo : Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for nombre in EFECTOS:
		var cfg : Dictionary = EFECTOS[nombre]
		var aleatorio = AudioStreamRandomizer.new()
		for archivo in cfg.archivos:
			aleatorio.add_stream(-1, load(CARPETA + archivo + ".wav"))
		aleatorio.random_pitch = cfg.get("tono", 1.0)
		aleatorio.playback_mode = AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS if cfg.archivos.size() > 2 else AudioStreamRandomizer.PLAYBACK_RANDOM
		var r = AudioStreamPlayer.new()
		r.stream = aleatorio
		r.volume_db = cfg.get("db", 0.0)
		r.max_polyphony = cfg.get("voces", 1)
		r.bus = BUS
		add_child(r)
		_reproductores[nombre] = r
	#clic en todos los botones: los que se creen después (tarjetas de la tienda...) y los que ya
	#están. Al arrancar, Godot mete la escena principal en el árbol antes del _ready de los
	#autoloads, así que sus botones no pasan por node_added: se buscan al acabar este frame
	get_tree().node_added.connect(_on_node_added)
	_conecta_existentes.call_deferred()

func toca(nombre : String) -> void:
	if nombre == "" or not _reproductores.has(nombre):
		return
	var cfg : Dictionary = EFECTOS[nombre]
	if not en_partida and not cfg.get("interfaz", false):
		return
	var ahora = Time.get_ticks_msec()
	if ahora - _ultimo.get(nombre, -100000) < cfg.get("intervalo", 0.0) * 1000.0:
		return
	_ultimo[nombre] = ahora
	_reproductores[nombre].play()

func _conecta_existentes() -> void:
	for b in get_tree().root.find_children("*", "BaseButton", true, false):
		_on_node_added(b)

func _on_node_added(nodo : Node) -> void:
	#la marca evita conectar dos veces el mismo botón
	if nodo is BaseButton and not nodo.has_meta(&"sonido"):
		nodo.set_meta(&"sonido", true)
		var sonido = "atras" if nodo.name in BOTONES_ATRAS else "click"
		nodo.pressed.connect(toca.bind(sonido))
		#tocar un botón desactivado (sin oro para comprar, dificultad bloqueada) suena a error
		nodo.gui_input.connect(_on_boton_input.bind(nodo))

func _on_boton_input(evento : InputEvent, boton : BaseButton) -> void:
	if boton.disabled and evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		toca("error")
