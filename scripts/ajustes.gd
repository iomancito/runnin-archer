extends Node
## Autoload Ajustes: volumen de música y efectos, calidad gráfica y FPS.
## Se guardan aparte del progreso (user://ajustes.cfg): borrar el progreso no los toca.
##
## Calidad: lo que más cuesta en el móvil son las sombras en tiempo real (~6-7 ms en Mali-G57) y
## la resolución 3D (100 % ≈ 32 ms frente a 24 ms al 75 %); ver docs/rendimiento.md. En "auto"
## se empieza en ALTA (o MEDIA en móviles con poca RAM) y, si en partida los FPS medios caen por
## debajo de UMBRAL_FPS, se baja un nivel y se recuerda. Nunca sube sola: subir de nivel en un
## móvil que va bien solo le quitaría fluidez.

signal calidad_cambiada

const ARCHIVO : String = "user://ajustes.cfg"
const BUS_EFECTOS : String = "Effects"

#volumen inicial de música y efectos (0..1)
const VOLUMEN_INICIAL : float = 0.5

#nivel -> sombras del sol y escala de la resolución 3D
const NIVELES : Dictionary = {
	"low": {"nombre": "Low", "sombras": false, "escala": 0.6},
	"medium": {"nombre": "Medium", "sombras": false, "escala": 0.75},
	"high": {"nombre": "High", "sombras": true, "escala": 0.75},
	"ultra": {"nombre": "Ultra", "sombras": true, "escala": 1.0},
}
const ORDEN_NIVELES : Array[String] = ["low", "medium", "high", "ultra"]
const OPCIONES_FPS : Array[int] = [30, 60]

#calidad automática: nivel de partida, RAM por debajo de la que se empieza en medio (bytes),
#segundos que se ignoran al empezar a medir (fundido, shaders), ventana de medida y umbral
const AUTO_INICIAL : String = "high"
const AUTO_RAM_BAJA : int = 3 * 1024 * 1024 * 1024
const AUTO_ESPERA : float = 3.0
const AUTO_VENTANA : float = 6.0
const UMBRAL_FPS : float = 28.0

var musica : float = VOLUMEN_INICIAL
var efectos : float = VOLUMEN_INICIAL
#"auto" o un nivel de NIVELES
var calidad : String = "auto"
#nivel elegido por la calidad automática ("" = aún no calculado)
var nivel_auto : String = ""
var fps : int = 60

var _midiendo : bool = false
var _espera : float = 0.0
var _tiempo : float = 0.0
var _frames : int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if AudioServer.get_bus_index(BUS_EFECTOS) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, BUS_EFECTOS)
	_carga()
	if nivel_auto == "":
		nivel_auto = _nivel_inicial()
	aplica()

#nivel de calidad en uso
func nivel() -> String:
	return nivel_auto if calidad == "auto" else calidad

func sombras() -> bool:
	return NIVELES[nivel()].sombras

#aplica audio, resolución y FPS (las sombras se aplican a cada mapa con aplica_a_mapa)
func aplica() -> void:
	Musica.volumen = musica
	var bus = AudioServer.get_bus_index(BUS_EFECTOS)
	AudioServer.set_bus_mute(bus, efectos <= 0.0)
	if efectos > 0.0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(efectos))
	get_tree().root.scaling_3d_scale = NIVELES[nivel()].escala
	Engine.max_fps = fps

#activa o quita las sombras de las luces direccionales del mapa según la calidad
func aplica_a_mapa(mapa : Node) -> void:
	for luz in mapa.find_children("*", "DirectionalLight3D", true, false):
		if not luz.has_meta("sombra_original"):
			luz.set_meta("sombra_original", luz.shadow_enabled)
		luz.shadow_enabled = luz.get_meta("sombra_original") and sombras()

#la partida empieza (true) o se para (false): solo se miden los FPS jugando
func mide(si : bool) -> void:
	_midiendo = si and calidad == "auto"
	_espera = AUTO_ESPERA
	_tiempo = 0.0
	_frames = 0

func _process(delta : float) -> void:
	if not _midiendo or get_tree().paused:
		return
	if _espera > 0.0:
		_espera -= delta
		return
	_tiempo += delta
	_frames += 1
	if _tiempo < AUTO_VENTANA:
		return
	var medidos = _frames / _tiempo
	var i = ORDEN_NIVELES.find(nivel_auto)
	#con el tope de 30 FPS el umbral baja en proporción
	if medidos < min(UMBRAL_FPS, fps * 0.8) and i > 0:
		nivel_auto = ORDEN_NIVELES[i - 1]
		print("Ajustes: %.1f FPS, calidad automática -> %s" % [medidos, nivel_auto])
		guarda()
		aplica()
		calidad_cambiada.emit()
		_espera = AUTO_ESPERA
	_tiempo = 0.0
	_frames = 0

#primera estimación por la memoria del móvil
func _nivel_inicial() -> String:
	var ram = OS.get_memory_info().get("physical", -1)
	if ram > 0 and ram < AUTO_RAM_BAJA:
		return "medium"
	return AUTO_INICIAL

func guarda() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "musica", musica)
	cfg.set_value("audio", "efectos", efectos)
	cfg.set_value("video", "calidad", calidad)
	cfg.set_value("video", "nivel_auto", nivel_auto)
	cfg.set_value("video", "fps", fps)
	cfg.save(ARCHIVO)

func _carga() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(ARCHIVO) != OK:
		return
	musica = clampf(cfg.get_value("audio", "musica", musica), 0.0, 1.0)
	efectos = clampf(cfg.get_value("audio", "efectos", efectos), 0.0, 1.0)
	calidad = cfg.get_value("video", "calidad", calidad)
	if calidad != "auto" and not NIVELES.has(calidad):
		calidad = "auto"
	nivel_auto = cfg.get_value("video", "nivel_auto", nivel_auto)
	if nivel_auto != "" and not NIVELES.has(nivel_auto):
		nivel_auto = ""
	fps = cfg.get_value("video", "fps", fps)
	if not fps in OPCIONES_FPS:
		fps = 60
