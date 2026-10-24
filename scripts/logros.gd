extends Node

## Logros del jugador (autoload "Logros"). Se guardan aparte de la partida (user://logros.json)
## y no se borran con RESET PROGRESS. Los umbrales están en Balance (LOGRO_*).
## Dos tipos:
##   - de estado: se deducen de Progreso o de las estadísticas totales (comprueba())
##   - de partida: se evalúan al superar un mapa (mapa_superado())

signal desbloqueado(id : String) #lo escucha el aviso emergente

const SAVE_PATH : String = "user://logros.json"
const SAVE_VERSION : int = 1
#grupo de los logros generales; los retos por mapa usan la clave de su dificultad
const GENERAL : String = "general"

#definiciones en orden de pantalla: {id, nombre, texto, grupo, progreso (Callable -> [actual, meta], opcional)}
var lista : Array = []
var por_id : Dictionary = {}
#id -> fecha de desbloqueo (unix)
var conseguidos : Dictionary = {}
#estadísticas totales de todas las partidas
var stats : Dictionary = {"bajas": 0, "oro": 0, "bosses": 0, "minijefes": 0, "horda": 0, "arcos": []}

#--- partida en curso (un mapa) ---
var corriendo : bool = false
var tiempo : float = 0.0
var golpeado : bool = false
var puertas : int = 0
var total_mapa : int = 0 #enemigos del plan + boss final
#los avisos no salen mientras se cargan logros antiguos
var _silencio : bool = false

func _ready() -> void:
	_define()
	_carga()
	#logros que ya se cumplían antes de existir el sistema: sin aviso
	_silencio = true
	comprueba()
	_silencio = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		guarda()

#se detiene solo con el árbol en pausa (pausa, resultados, app en segundo plano)
func _physics_process(delta: float) -> void:
	if corriendo:
		tiempo += delta

#--- Definiciones ---

func _define() -> void:
	var bajas = Balance.LOGRO_BAJAS
	_add("first_blood", "First Blood", "Defeat your first enemy", GENERAL, _stat.bind("bajas", bajas[0]))
	_add("hunter", "Hunter", "Defeat %s enemies" % num_txt(bajas[1]), GENERAL, _stat.bind("bajas", bajas[1]))
	_add("slayer", "Slayer", "Defeat %s enemies" % num_txt(bajas[2]), GENERAL, _stat.bind("bajas", bajas[2]))
	_add("legend", "Living Legend", "Defeat %s enemies" % num_txt(bajas[3]), GENERAL, _stat.bind("bajas", bajas[3]))
	var oro = Balance.LOGRO_ORO
	_add("gold_1", "Pocket Money", "Earn %s gold" % num_txt(oro[0]), GENERAL, _stat.bind("oro", oro[0]))
	_add("gold_2", "Treasure Hunter", "Earn %s gold" % num_txt(oro[1]), GENERAL, _stat.bind("oro", oro[1]))
	_add("gold_3", "Dragon's Hoard", "Earn %s gold" % num_txt(oro[2]), GENERAL, _stat.bind("oro", oro[2]))
	for m in [1, 2, 3]:
		_add("map_%d" % m, "Map %d Cleared" % m, "Defeat the boss of map %d" % m, GENERAL)
	var titulos = {"easy": "Apprentice", "medium": "Ranger", "hard": "Veteran", "hell": "Hellwalker"}
	for d in Balance.ORDEN_DIFICULTADES:
		_add("clear_%s" % d, titulos.get(d, d), "Clear all 3 maps on %s" % Balance.DIFICULTADES[d].nombre, GENERAL)
	_add("first_upgrade", "Getting Stronger", "Buy an upgrade in the shop", GENERAL)
	for t in Balance.tienda():
		_add("max_" + t[0], "Master of %s" % t[1], "Max out %s" % t[1], GENERAL, _nivel_mejora.bind(t[0], t[5].size()))
	_add("max_all", "Fully Upgraded", "Max out every upgrade", GENERAL, _mejoras_al_maximo)
	_add("first_bow", "Special Delivery", "Buy a special bow", GENERAL)
	_add("bow_master", "Bow Master", "Upgrade a special bow to level %d" % Balance.ARCO_NIVEL_MAX, GENERAL)
	_add("bow_collector", "Collector", "Own every special bow at some point", GENERAL,
			func(): return [stats.arcos.size(), Balance.ORDEN_ARCOS.size()])
	_add("boss_hunter", "Dragon Hunter", "Defeat %d bosses" % Balance.LOGRO_BOSSES, GENERAL, _stat.bind("bosses", Balance.LOGRO_BOSSES))
	_add("giant_slayer", "Giant Slayer", "Defeat %d mini bosses" % Balance.LOGRO_MINIJEFES, GENERAL, _stat.bind("minijefes", Balance.LOGRO_MINIJEFES))
	_add("horde_breaker", "Horde Breaker", "Defeat %s horde enemies" % num_txt(Balance.LOGRO_HORDA), GENERAL, _stat.bind("horda", Balance.LOGRO_HORDA))
	_add("full_quiver", "Full Quiver", "Shoot %d arrows at once" % Balance.MAX_FLECHAS, GENERAL)
	_add("lone_wolf", "Lone Wolf", "Clear a map without passing through any gate", GENERAL)
	_add("close_call", "Close Call", "Defeat a boss with less than %d%% HP left" % roundi(Balance.LOGRO_VIDA_AGONICA * 100), GENERAL)
	_add("untouchable", "Untouchable", "Clear a map without taking damage", GENERAL)
	_add("untouchable_hell", "Hell's Ghost", "Clear a map on Hell without taking damage", GENERAL)
	#retos por mapa y dificultad
	for d in Balance.ORDEN_DIFICULTADES:
		var nombre = Balance.DIFICULTADES[d].nombre
		var limite = _tiempo_txt(tiempo_limite(d))
		for m in [1, 2, 3]:
			_add(_id_reto("exterminator", d, m), "Exterminator %d" % m, "Clear map %d on %s killing every enemy" % [m, nombre], d)
			_add(_id_reto("swift", d, m), "Swift Hunter %d" % m, "Clear map %d on %s in under %s" % [m, nombre, limite], d)
			_add(_id_reto("perfect", d, m), "Perfect Hunt %d" % m, "Clear map %d on %s killing every enemy in under %s" % [m, nombre, limite], d)

func _add(id : String, nombre : String, texto : String, grupo : String, progreso : Callable = Callable()) -> void:
	var l = {"id": id, "nombre": nombre, "texto": texto, "grupo": grupo, "progreso": progreso}
	lista.append(l)
	por_id[id] = l

func _id_reto(tipo : String, d : String, m : int) -> String:
	return "%s_%s_%d" % [tipo, d, m]

func _stat(clave : String, meta : int) -> Array:
	return [mini(stats[clave], meta), meta]

func _nivel_mejora(nombre : String, maximo : int) -> Array:
	return [Progreso.niveles.get(nombre, 0), maximo]

func _mejoras_al_maximo() -> Array:
	var tienda = Balance.tienda()
	var n = 0
	for t in tienda:
		if Progreso.niveles.get(t[0], 0) >= t[5].size():
			n += 1
	return [n, tienda.size()]

func tiempo_limite(d : String) -> float:
	return Balance.LOGRO_TIEMPO.get(d, Balance.LOGRO_TIEMPO["medium"])

func _tiempo_txt(seg : float) -> String:
	return "%d:%02d" % [int(seg) / 60, int(seg) % 60]

#1000 -> "1,000"
func num_txt(n : int) -> String:
	var s = str(n)
	var r = ""
	while s.length() > 3:
		r = "," + s.substr(s.length() - 3) + r
		s = s.substr(0, s.length() - 3)
	return s + r

#--- Consultas para la pantalla ---

func tiene(id : String) -> bool:
	return conseguidos.has(id)

#[actual, meta] o [] si el logro no tiene progreso
func progreso_de(id : String) -> Array:
	var p : Callable = por_id[id].progreso
	return p.call() if p.is_valid() else []

func total_conseguidos() -> int:
	return conseguidos.size()

#--- Desbloqueo ---

func desbloquea(id : String) -> void:
	if tiene(id) or not por_id.has(id):
		return
	conseguidos[id] = int(Time.get_unix_time_from_system())
	if not _silencio:
		desbloqueado.emit(id)
	guarda()

#logros de estado: progreso, tienda, arcos y estadísticas totales
func comprueba() -> void:
	for l in lista:
		var p = progreso_de(l.id)
		if not p.is_empty() and p[0] >= p[1]:
			desbloquea(l.id)
	for m in [1, 2, 3]:
		for d in Progreso.max_maps:
			#max_maps guarda el mapa alcanzado: superar el m deja en m + 1
			if Progreso.max_maps[d] > m:
				desbloquea("map_%d" % m)
	for d in Progreso.completadas:
		desbloquea("map_3")
		desbloquea("clear_%s" % d)
	if not Progreso.niveles.is_empty() and Progreso.niveles.values().max() > 0:
		desbloquea("first_upgrade")
	if Progreso.arco != "":
		if not Progreso.arco in stats.arcos:
			stats.arcos.append(Progreso.arco)
		desbloquea("first_bow")
		if Progreso.arco_nivel >= Balance.ARCO_NIVEL_MAX:
			desbloquea("bow_master")
		comprueba_id("bow_collector")

func comprueba_id(id : String) -> void:
	var p = progreso_de(id)
	if not p.is_empty() and p[0] >= p[1]:
		desbloquea(id)

#--- Eventos de la partida ---

func empieza_mapa(total : int) -> void:
	corriendo = true
	tiempo = 0.0
	golpeado = false
	puertas = 0
	total_mapa = total

#muerte del player o abandonar: guarda lo acumulado
func termina_partida() -> void:
	corriendo = false
	guarda()

#enemigo muerto por el player (no al chocar); oro = lo ganado con el bonus
func baja(enemigo : Enemy, oro : int) -> void:
	stats.bajas += 1
	stats.oro += oro
	if enemigo is Boss:
		stats.bosses += 1
	elif enemigo.tipo == Niveles.MAPAS.get(enemigo.mapa, {}).get("jefes", {}).get("tipo", ""):
		stats.minijefes += 1
	if enemigo.horda:
		stats.horda += 1
	#solo los logros de contador (comprueba() entero sería caro con muchas bajas por segundo)
	for id in ["first_blood", "hunter", "slayer", "legend", "gold_1", "gold_2", "gold_3", "boss_hunter", "giant_slayer", "horde_breaker"]:
		if not tiene(id):
			comprueba_id(id)

func golpe() -> void:
	golpeado = true

func puerta(player : Player) -> void:
	puertas += 1
	if player.stats["f_cantidad"] >= Balance.MAX_FLECHAS:
		desbloquea("full_quiver")

#boss del mapa muerto; bajas = bajas de esta partida (incluye el boss)
func mapa_superado(m : int, d : String, bajas : int, player : Player) -> void:
	corriendo = false
	var todos = bajas >= total_mapa
	var rapido = tiempo <= tiempo_limite(d)
	if todos:
		desbloquea(_id_reto("exterminator", d, m))
	if rapido:
		desbloquea(_id_reto("swift", d, m))
	if todos and rapido:
		desbloquea(_id_reto("perfect", d, m))
	if puertas == 0:
		desbloquea("lone_wolf")
	if not golpeado:
		desbloquea("untouchable")
		if d == "hell":
			desbloquea("untouchable_hell")
	if is_instance_valid(player) and player.vida < player.stats["p_vida"] * Balance.LOGRO_VIDA_AGONICA:
		desbloquea("close_call")
	comprueba()
	guarda()

#--- Guardado ---

func guarda() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("No se pudieron guardar los logros: " + error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "conseguidos": conseguidos, "stats": stats}, "\t"))

func _carga() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Logros guardados corruptos, se ignoran")
		return
	var c = data.get("conseguidos", {})
	if typeof(c) == TYPE_DICTIONARY:
		for id in c:
			#se ignoran logros que ya no existen
			if por_id.has(id):
				conseguidos[id] = int(c[id])
	var s = data.get("stats", {})
	if typeof(s) == TYPE_DICTIONARY:
		for clave in stats:
			if clave == "arcos":
				for a in s.get("arcos", []):
					if Balance.ARCOS.has(a) and not a in stats.arcos:
						stats.arcos.append(a)
			else:
				stats[clave] = int(s.get(clave, 0)) #JSON devuelve floats
