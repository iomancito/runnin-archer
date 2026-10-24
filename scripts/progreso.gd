class_name Progress extends Node

##Señales
signal gold_changed(gold : int) #actualiza el oro en el hud

const SAVE_PATH : String = "user://save.json"
const SAVE_VERSION : int = 1

#stats base del player, sin mejoras
const BASE_STATS ={
	"p_speed" : 200,
	"p_side_speed" : 150,
	"p_attack_speed" : 0.5,
	"p_vida" : 10,
	"a_skin" : 1,
	"f_cantidad" : 1,
	"f_velocidad" : 500,
	"f_max_distancia" : 10,
	"f_daño" : 1
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
var max_map : int = 1 #mapa más alto alcanzado
var player
#estadísticas de la partida actual (pantalla de resultados)
var run_kills : int = 0
var run_gold : int = 0

func _ready() -> void:
	load_game()

func _notification(what: int) -> void:
	#guarda al cerrar la ventana o al pasar la app a segundo plano (android)
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()

func reset_run() -> void:
	run_kills = 0
	run_gold = 0

func save_game() -> void:
	var data = {
		"version": SAVE_VERSION,
		"gold": p_gold,
		"niveles": niveles,
		"max_map": max_map,
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
	max_map = int(data.get("max_map", 1))
	progreso_permanente["a_skin"] = int(data.get("skin", 1))
	niveles.clear()
	var saved_niveles = data.get("niveles", {})
	if typeof(saved_niveles) == TYPE_DICTIONARY:
		for nombre in saved_niveles:
			niveles[nombre] = int(saved_niveles[nombre]) #JSON devuelve floats
