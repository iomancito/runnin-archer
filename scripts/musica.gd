extends Node
## Autoload Musica: una pista de fondo cada vez, con fundido cruzado entre dos reproductores.
##
## Las pistas son OGG en res://assets/musica/<archivo>.ogg (por defecto archivo = nombre de la
## pista), generados con tools/convertir_musica.sh. Si falta uno se usa su alternativa
## (PISTAS[nombre].alternativa) y si no hay ninguna se apaga la música.
## Las pistas con bucle se repiten enteras: el OGG ya trae el fundido entre final y principio.
## Las de un solo uso (jingles) acaban en silencio.
## El volumen del bus lo pone Ajustes (volumen) y la pausa lo baja (atenua).

const CARPETA : String = "res://assets/musica/"
const BUS : String = "Music"

#nombre -> bucle, pista que suena si falta el archivo ("" = ninguna) y archivo si no es el nombre
const PISTAS : Dictionary = {
	"menu": {"bucle": true, "alternativa": ""},
	"tienda": {"bucle": true, "alternativa": "menu"},
	#la canción de la victoria final, en bucle
	"creditos": {"bucle": true, "alternativa": "menu", "archivo": "final"},
	"mapa1": {"bucle": true, "alternativa": ""},
	"mapa2": {"bucle": true, "alternativa": "mapa1"},
	"mapa3": {"bucle": true, "alternativa": "mapa2"},
	"boss1": {"bucle": true, "alternativa": "boss"},
	"boss2": {"bucle": true, "alternativa": "boss"},
	"boss3": {"bucle": true, "alternativa": "boss"},
	"boss": {"bucle": true, "alternativa": ""},
	"victoria": {"bucle": false, "alternativa": ""},
	"derrota": {"bucle": false, "alternativa": ""},
	"final": {"bucle": false, "alternativa": "victoria"},
}

#segundos del fundido cruzado normal y del rápido (jingles, que deben entrar ya)
const FUNDIDO : float = 1.2
const FUNDIDO_RAPIDO : float = 0.3
#volumen de los reproductores (dB; el del jugador va en el bus) y cuánto baja con la pausa
const VOLUMEN_DB : float = 0.0
const PAUSA_DB : float = -12.0
#por debajo de esto se considera silencio
const SILENCIO_DB : float = -60.0

var _reproductores : Array[AudioStreamPlayer] = []
#índice del reproductor que suena ahora
var _activo : int = 0
var _pista_actual : String = ""
var _tween : Tween
#la atenuación de pausa va en el volumen del bus, aparte de los fundidos entre pistas
var _tween_bus : Tween
var _atenuada : bool = false
#volumen elegido en ajustes (0..1, 0 = silencio) y atenuación actual de la pausa (dB)
var volumen : float = 1.0 : set = _set_volumen
var _atenuacion_db : float = 0.0
#streams ya cargados (cada pista se carga la primera vez que suena)
var _cache : Dictionary = {}

func _ready() -> void:
	#la música sigue en pausa (menús y resultados congelan el árbol)
	process_mode = Node.PROCESS_MODE_ALWAYS
	if AudioServer.get_bus_index(BUS) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, BUS)
	_aplica_bus()
	for i in 2:
		var r = AudioStreamPlayer.new()
		r.bus = BUS
		r.volume_db = SILENCIO_DB
		add_child(r)
		_reproductores.append(r)
		#al acabar un jingle no suena nada: la próxima vez que se pida volverá a sonar
		r.finished.connect(func(): if r == _reproductores[_activo]: _pista_actual = "")

#pone la pista con fundido cruzado; si ya suena no hace nada
func toca(nombre : String) -> void:
	var real = _resuelve(nombre)
	if real == "":
		if _pista_actual != "":
			para()
		return
	if real == _pista_actual:
		return
	var stream = _carga(real)
	_pista_actual = real
	var bucle = PISTAS[real].bucle
	var duracion = FUNDIDO if bucle else FUNDIDO_RAPIDO
	var saliente = _reproductores[_activo]
	_activo = 1 - _activo
	var entrante = _reproductores[_activo]
	entrante.stream = stream
	entrante.volume_db = SILENCIO_DB
	entrante.play()
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.tween_property(entrante, "volume_db", VOLUMEN_DB, duracion)
	_tween.tween_property(saliente, "volume_db", SILENCIO_DB, duracion)
	_tween.chain().tween_callback(saliente.stop)

#apaga la música con fundido
func para(duracion : float = FUNDIDO) -> void:
	_pista_actual = ""
	if _tween:
		_tween.kill()
	#los dos: puede haber un fundido cruzado a medias
	_tween = create_tween().set_parallel()
	for r in _reproductores:
		_tween.tween_property(r, "volume_db", SILENCIO_DB, duracion)
	_tween.chain().tween_callback(func(): for r in _reproductores: r.stop())

#baja el volumen con el menú de pausa abierto
func atenua(si : bool) -> void:
	if si == _atenuada:
		return
	_atenuada = si
	if _tween_bus:
		_tween_bus.kill()
	_tween_bus = create_tween()
	_tween_bus.tween_method(func(db): _atenuacion_db = db; _aplica_bus(),
		_atenuacion_db, PAUSA_DB if si else 0.0, FUNDIDO_RAPIDO)

func _set_volumen(v : float) -> void:
	volumen = clampf(v, 0.0, 1.0)
	_aplica_bus()

func _aplica_bus() -> void:
	var bus = AudioServer.get_bus_index(BUS)
	if bus == -1:
		return
	AudioServer.set_bus_mute(bus, volumen <= 0.0)
	if volumen > 0.0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(volumen) + _atenuacion_db)

#primera pista con archivo siguiendo la cadena de alternativas ("" si ninguna)
func _resuelve(nombre : String) -> String:
	var n = nombre
	while n != "":
		if not PISTAS.has(n):
			push_warning("Musica: pista desconocida '%s'" % n)
			return ""
		if _cache.has(n) or ResourceLoader.exists(_ruta(n)):
			return n
		n = PISTAS[n].alternativa
	return ""

func _ruta(nombre : String) -> String:
	return CARPETA + PISTAS[nombre].get("archivo", nombre) + ".ogg"

func _carga(nombre : String) -> AudioStream:
	if not _cache.has(nombre):
		var stream = load(_ruta(nombre))
		#el bucle se fija aquí para no depender de la opción de importación; una copia si el
		#archivo lo comparte otra pista (comparten los datos de audio, no ocupan el doble)
		if stream is AudioStreamOggVorbis:
			if PISTAS[nombre].has("archivo"):
				stream = stream.duplicate()
			stream.loop = PISTAS[nombre].bucle
		_cache[nombre] = stream
	return _cache[nombre]
