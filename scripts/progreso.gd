class_name Progress extends Node

##Señales
signal gold_changed(gold : int) #actualiza el oro en el hud
signal progress_reset #se ha borrado todo el progreso

const SAVE_PATH : String = "user://save.json"
const SAVE_VERSION : int = 4
#versión 1: la tienda costaba 1-5 de oro por nivel (se reembolsa al migrar)
const COSTES_V1 : Array[int] = [1, 2, 3, 4, 5]

#stats base del player, sin mejoras
const BASE_STATS ={
	"p_speed" : 200,
	"p_side_speed" : 150,
	"p_attack_speed" : 1.0,
	"p_vida" : 10,
	"a_skin" : 1,
	"f_cantidad" : 1,
	"f_velocidad" : 600,
	"f_max_distancia" : 10,
	"f_daño" : 1,
	"p_oro" : 0 #% extra de oro por enemigo
}

#stats base + mejoras compradas, lo recalcula Mejoras a partir de niveles
var progreso_permanente = BASE_STATS.duplicate()
#nombre de la pasiva -> nivel comprado
var niveles : Dictionary = {}
#Player stats
var p_gold : int = 0:
	set(value):
		p_gold = value
		gold_changed.emit(p_gold)
var current_map = 1
#dificultad elegida (clave de Balance.DIFICULTADES)
var dificultad : String = "easy":
	set(v):
		dificultad = v
		Balance.dificultad = v
#dificultades disponibles: se empieza solo con la primera y superar los 3 mapas
#en una dificultad desbloquea la siguiente (Balance.ORDEN_DIFICULTADES)
var desbloqueadas : Array = [Balance.ORDEN_DIFICULTADES[0]]
#mapa más alto alcanzado en cada dificultad
var max_maps : Dictionary = {}
#mapa más alto alcanzado en la dificultad actual
var max_map : int:
	get: return max_maps.get(dificultad, 1)
	set(v): max_maps[dificultad] = v
var player
#estadísticas de la partida actual (pantalla de resultados)
var run_kills : int = 0
var run_gold : int = 0
#fracción de oro pendiente por el bonus de oro (se acumula entre muertes)
var oro_resto : float = 0.0
#mensaje de un solo uso para el menú principal (p.ej. reembolso al migrar)
var aviso : String = ""

func _ready() -> void:
	Balance.dificultad = dificultad
	load_game()

func _notification(what: int) -> void:
	#guarda al cerrar la ventana o al pasar la app a segundo plano (android)
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()

func reset_run() -> void:
	run_kills = 0
	run_gold = 0

func esta_desbloqueada(d : String) -> bool:
	return d in desbloqueadas

#siguiente dificultad del orden, o "" si es la última
func siguiente_dificultad(d : String) -> String:
	var i = Balance.ORDEN_DIFICULTADES.find(d)
	if i < 0 or i + 1 >= Balance.ORDEN_DIFICULTADES.size():
		return ""
	return Balance.ORDEN_DIFICULTADES[i + 1]

#se han superado los 3 mapas en la dificultad actual: desbloquea la siguiente.
#Devuelve la dificultad recién desbloqueada o "" si ya lo estaba / no hay más
func completa_dificultad() -> String:
	var nueva = siguiente_dificultad(dificultad)
	if nueva == "" or esta_desbloqueada(nueva):
		return ""
	desbloqueadas.append(nueva)
	save_game()
	return nueva

#borra todo: oro, mejoras compradas, mapas superados y dificultades desbloqueadas
func reset_all() -> void:
	niveles.clear()
	max_maps.clear()
	desbloqueadas = [Balance.ORDEN_DIFICULTADES[0]]
	dificultad = Balance.ORDEN_DIFICULTADES[0]
	current_map = 1
	oro_resto = 0.0
	p_gold = 0
	save_game()
	progress_reset.emit()

func save_game() -> void:
	var data = {
		"version": SAVE_VERSION,
		"gold": p_gold,
		"niveles": niveles,
		"max_maps": max_maps,
		"dificultad": dificultad,
		"desbloqueadas": desbloqueadas,
		"skin": progreso_permanente["a_skin"]
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("No se pudo guardar la partida: " + error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data, "\t"))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Partida guardada corrupta, se ignora")
		return
	p_gold = int(data.get("gold", 0))
	dificultad = data.get("dificultad", "medium")
	if not Balance.DIFICULTADES.has(dificultad):
		dificultad = "medium"
	max_maps.clear()
	var saved_maps = data.get("max_maps", {})
	if typeof(saved_maps) == TYPE_DICTIONARY:
		for d in saved_maps:
			max_maps[d] = int(saved_maps[d])
	#versión 2 o anterior: un único mapa máximo, se asigna a la dificultad normal
	if data.has("max_map") and not data.has("max_maps"):
		max_maps["medium"] = int(data["max_map"])
	progreso_permanente["a_skin"] = int(data.get("skin", 1))
	niveles.clear()
	var saved_niveles = data.get("niveles", {})
	if typeof(saved_niveles) == TYPE_DICTIONARY:
		for nombre in saved_niveles:
			niveles[nombre] = int(saved_niveles[nombre]) #JSON devuelve floats
	desbloqueadas = [Balance.ORDEN_DIFICULTADES[0]]
	var saved_desbloqueadas = data.get("desbloqueadas", [])
	if typeof(saved_desbloqueadas) == TYPE_ARRAY:
		for d in saved_desbloqueadas:
			if Balance.DIFICULTADES.has(d) and not d in desbloqueadas:
				desbloqueadas.append(d)
	#versión 3 o anterior: todas las dificultades estaban abiertas; se conservan las ya jugadas o elegidas
	if int(data.get("version", 1)) < 4:
		for d in Balance.ORDEN_DIFICULTADES:
			if (max_maps.has(d) or d == dificultad) and not d in desbloqueadas:
				desbloqueadas.append(d)
	if not esta_desbloqueada(dificultad):
		dificultad = desbloqueadas[0]
	if int(data.get("version", 1)) < 2:
		_migra_v1()

#la tienda cambió de mejoras y precios: se devuelve todo lo gastado
func _migra_v1() -> void:
	var reembolso = 0
	for nombre in niveles:
		for i in min(niveles[nombre], COSTES_V1.size()):
			reembolso += COSTES_V1[i]
	niveles.clear()
	p_gold += reembolso
	aviso = "Shop rebalanced: upgrades refunded (+%d gold)" % reembolso
	save_game()

#oro de un enemigo con el bonus de la tienda aplicado
func oro_con_bonus(cantidad : int) -> int:
	var bonus = progreso_permanente.get("p_oro", 0) / 100.0
	var total = cantidad * (1.0 + bonus) + oro_resto
	var entero = int(floor(total))
	oro_resto = total - entero
	return entero
