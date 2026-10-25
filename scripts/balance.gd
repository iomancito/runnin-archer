class_name Balance

## Todos los números de balance del juego en un solo sitio.
## Daño que el player puede hacer a un enemigo antes de chocar con él:
##   (alcance / velocidad de carrera) * cadencia * daño * flechas
## Con los stats base son ~3 puntos; con la tienda al máximo ~990.

#--- Enemigos: valores en el mapa 1 al inicio del recorrido ---
const ENEMIGOS = {
	"goblin": {"vida": 2, "daño": 2, "oro": 1},
	"orc": {"vida": 5, "daño": 3, "oro": 2},
	"troll": {"vida": 14, "daño": 5, "oro": 4},
	"ogre": {"vida": 30, "daño": 8, "oro": 10},
	"whelp": {"vida": 7, "daño": 3, "oro": 3}, #cría de dragón: escupe fuego, final del mapa 1
	"zombie": {"vida": 4, "daño": 2, "oro": 1},
	"brute": {"vida": 25, "daño": 6, "oro": 8, "velocidad": 1.0}, #zombi gordo, mini jefe del mapa 2
	"skeleton": {"vida": 3, "daño": 2, "oro": 1, "velocidad": 1.6},
	"skeleton_mage": {"vida": 6, "daño": 3, "oro": 3}, #lanza rayos
	"reaper": {"vida": 12, "daño": 5, "oro": 4, "velocidad": 0.8},
	"death_knight": {"vida": 32, "daño": 8, "oro": 10}, #mini jefe del mapa 3
}
const ROCA_TROLL_DAÑO = 4
#enemigos que disparan (Lanzador): daño del proyectil, y cuándo y cuánto disparan.
## distancia: metros por delante del player a los que empiezan; recarga: segundos entre disparos;
## aviso: segundos que la marca está en el suelo antes del impacto (lo que hay para esquivar);
## radio: metros del impacto
const PROYECTIL_DAÑO = {"whelp": 3, "skeleton_mage": 4}
const LANZADOR = {"distancia": 20.0, "recarga": 2.4, "disparos": 2, "aviso": 1.2, "radio": 0.9}
#la vida crece con la distancia: x1 al inicio, x3.5 a los 1000 m
const VIDA_POR_METRO = 1.0 / 400.0
#multiplicadores por mapa: [vida, daño, oro]
const MAPAS = {1: [1.0, 1.0, 1.0], 2: [3.0, 1.5, 1.5], 3: [7.0, 2.0, 2.0]}

#--- Hordas: grupos compactos de enemigos débiles (diseño en Niveles, frecuencia por dificultad) ---
#multiplicadores de cada miembro de una horda sobre los valores normales de su tipo
const HORDA = {"vida": 0.5, "daño": 0.5, "oro": 0.5}

#--- Dificultad: multiplica vida, daño, densidad de enemigos y oro (también de los bosses) ---
## hordas: multiplica la frecuencia de las hordas del mapa (0 = sin hordas)
const DIFICULTADES = {
	"easy": {"nombre": "Easy", "vida": 0.6, "daño": 0.5, "densidad": 0.75, "oro": 0.6, "boss_intervalo": 1.3, "hordas": 0.0},
	"medium": {"nombre": "Medium", "vida": 1.0, "daño": 1.0, "densidad": 1.0, "oro": 1.0, "boss_intervalo": 1.0, "hordas": 0.0},
	"hard": {"nombre": "Hard", "vida": 1.7, "daño": 1.5, "densidad": 1.25, "oro": 1.6, "boss_intervalo": 0.9, "hordas": 1.0},
	"hell": {"nombre": "Hell", "vida": 3.0, "daño": 2.5, "densidad": 1.5, "oro": 2.5, "boss_intervalo": 0.75, "hordas": 1.6},
}
const ORDEN_DIFICULTADES = ["easy", "medium", "hard", "hell"]

#dificultad actual: la sincroniza Progreso al cargar o elegirla en el menú
static var dificultad : String = "easy"

static func dif() -> Dictionary:
	return DIFICULTADES.get(dificultad, DIFICULTADES["medium"])

#--- Bosses (mapa 1, se multiplican igual que los enemigos) ---
const BOSS_VIDA = 350
const BOSS_DAÑO = 3
const BOSS_INTERVALO = 2.5 #segundos entre ataques mientras el player está parado delante
const BOSS_ORO = 100
#--- Ataques de los bosses: proyectiles que marcan el suelo donde caerán y se esquivan ---
## Tipos (la secuencia de cada boss está en Niveles.MAPAS[n].boss_ataques):
##   bola:    ráfaga de bolas a donde está (o estará) el player
##   barrera: fuego en todos los carriles menos "libres"; siempre hay uno libre al lado
##   lluvia:  "oleadas" de fuego del cielo por carriles; el carril libre cambia en cada oleada
## Por dificultad:
##   aviso: segundos entre la marca en el suelo y el impacto (con Dodge Speed base se recorren
##          2,5 m/s: hacen falta ~0,6 s para salir de una bola y ~0,8 s para cambiar de carril)
##   rafaga: bolas por ataque "bola"; prediccion: 0 = apunta a donde está, 1 = a donde estará
##   libres: carriles sin fuego en "barrera" y "lluvia"; oleadas: oleadas de "lluvia"
const BOSS_ATAQUES = {
	"easy": {"aviso": 1.5, "rafaga": 1, "prediccion": 0.0, "libres": 2, "oleadas": 1},
	"medium": {"aviso": 1.25, "rafaga": 2, "prediccion": 0.3, "libres": 2, "oleadas": 1},
	"hard": {"aviso": 1.05, "rafaga": 3, "prediccion": 0.6, "libres": 1, "oleadas": 2},
	"hell": {"aviso": 0.9, "rafaga": 4, "prediccion": 0.9, "libres": 1, "oleadas": 3},
}
const BOSS_BOLA_RADIO = 1.1 #metros del impacto de una bola
const BOSS_RAFAGA_CADENCIA = 0.45 #segundos entre las bolas de una ráfaga
const BOSS_AVISO_CARRILES = 1.2 #"barrera" y "lluvia" dan más tiempo: hay que cambiar de carril
const BOSS_OLEADAS_PAUSA = 0.5 #segundos entre el impacto de una oleada y el de la siguiente
#mitad del ancho del player para los impactos (un roce cuenta)
const RADIO_PLAYER = 0.3

#--- Tienda: nombre (clave de guardado), título, formato, stat, incremento, costes por nivel ---
static func tienda() -> Array:
	return [
		["damage", "Damage", "%d", "f_daño", 1, costes(12, 1.4, 10)],
		["attack_speed", "Fire Rate", "%.1f/s", "p_attack_speed", 0.1, costes(12, 1.4, 10)],
		["arrow_number", "Arrows", "%d", "f_cantidad", 1, [50, 150, 400, 900]],
		["vida", "Max HP", "%d", "p_vida", 5, costes(8, 1.4, 10)],
		["range", "Range", "%d m", "f_max_distancia", 2, costes(8, 1.4, 10)],
		["dodge", "Dodge Speed", "%d", "p_side_speed", 10, costes(6, 1.4, 10)],
		#correr más acorta el mapa pero también el tiempo para disparar a cada enemigo
		["run_speed", "Run Speed", "%d", "p_speed", 10, costes(10, 1.4, 10)],
		["arrow_speed", "Arrow Speed", "%d", "f_velocidad", 40, costes(6, 1.4, 10)],
		["gold_bonus", "Gold Bonus", "+%d%%", "p_oro", 10, costes(15, 1.4, 10)],
	]

#--- Puertas de mejora durante la partida: texto, stat, incremento ---
const PUERTAS = [
	["Damage\n+1", "f_daño", 1],
	["Fire rate\n+0.15/s", "p_attack_speed", 0.15],
	["Arrows\n+1", "f_cantidad", 1],
	["Range\n+3 m", "f_max_distancia", 3],
	["Dodge speed\n+15", "p_side_speed", 15],
	["Max HP\n+10", "p_vida", 10],
]
#tope de flechas por disparo (tienda + puertas)
const MAX_FLECHAS = 7

#--- Arcos especiales: se compran en la tienda tras superar los 3 mapas de su dificultad ---
## Solo se tiene un arco a la vez: comprar el mismo lo sube de nivel; comprar otro lo equipa
## en nivel 1 y se pierden las mejoras del anterior. Cada valor es [nivel 1, suma por nivel].
## Un arco superior es mejor a igual nivel, pero un arco inferior mejorado puede superarlo.
const ARCO_NIVEL_MAX = 5
const ARCOS = {
	"thorn": {
		"nombre": "Thorn Bow", "modelo": 3, "dificultad": "easy", "coste": [150, 1.6],
		"daño": [1.10, 0.05],
		"perfora": [1, 1], #enemigos extra que atraviesa cada flecha
	},
	"sunfire": {
		"nombre": "Sunfire Bow", "modelo": 2, "dificultad": "medium", "coste": [400, 1.6],
		"daño": [1.20, 0.05],
		"explosion_radio": [1.5, 0.25], #metros
		"explosion_daño": [0.4, 0.15], #fracción del daño de la flecha a los de alrededor
	},
	"storm": {
		"nombre": "Storm Bow", "modelo": 5, "dificultad": "hard", "coste": [1000, 1.6],
		"daño": [1.30, 0.05],
		"cadencia": [1.15, 0.0],
		"cadena_saltos": [2, 1], #enemigos a los que salta el rayo
		"cadena_daño": [0.5, 0.1],
		"cadena_radio": [7.0, 0.0],
	},
	"dragon": {
		"nombre": "Dragonbone Bow", "modelo": 4, "dificultad": "hell", "coste": [2500, 1.6],
		"daño": [1.50, 0.05],
		"quemadura_dps": [0.4, 0.15], #fracción del daño de la flecha por segundo
		"quemadura_seg": [3.0, 0.0],
		"daño_boss": [0.3, 0.15], #daño extra contra bosses
	},
}
const ORDEN_ARCOS = ["thorn", "sunfire", "storm", "dragon"]
#valor neutro de cada parámetro si el arco no lo tiene (o sin arco especial)
const ARCO_NEUTRO = {"daño": 1.0, "cadencia": 1.0}

#--- Logros (definiciones en scripts/logros.gd) ---
#bajas totales: la primera y los tres niveles de cazador
const LOGRO_BAJAS = [1, 500, 5000, 25000]
#oro ganado en total
const LOGRO_ORO = [1000, 25000, 100000]
const LOGRO_BOSSES = 25
const LOGRO_MINIJEFES = 25
const LOGRO_HORDA = 1000
#fracción de vida máxima por debajo de la cual matar al boss cuenta como "por los pelos"
const LOGRO_VIDA_AGONICA = 0.1
#tiempo límite (s) de Swift Hunter / Perfect Hunt por dificultad, igual en los 3 mapas.
#Recorrer un mapa lleva 300 s a velocidad base y 200 s con Run Speed al máximo; el player
#solo se para ante el boss: hace falta mejorar la carrera y matar al boss rápido
const LOGRO_TIEMPO = {"easy": 240.0, "medium": 240.0, "hard": 250.0, "hell": 260.0}

static func costes(base : float, crecimiento : float, niveles : int) -> Array[int]:
	var r : Array[int] = []
	for i in niveles:
		r.append(int(round(base * pow(crecimiento, i))))
	return r

#valor de un parámetro del arco a un nivel (1..ARCO_NIVEL_MAX); "" = arco original
static func arco_valor(id : String, clave : String, nivel : int) -> float:
	if id == "" or not ARCOS.has(id) or not ARCOS[id].has(clave) or nivel < 1:
		return ARCO_NEUTRO.get(clave, 0.0)
	var v = ARCOS[id][clave]
	return v[0] + v[1] * (nivel - 1)

#precio de comprar el nivel indicado del arco
static func arco_coste(id : String, nivel : int) -> int:
	var c = ARCOS[id].coste
	return int(round(c[0] * pow(c[1], nivel - 1)))

#texto de la habilidad para la tienda (valores al nivel indicado)
static func arco_descripcion(id : String, nivel : int) -> String:
	var v = func(clave): return arco_valor(id, clave, nivel)
	var texto = ""
	match id:
		"thorn":
			texto = "Arrows pierce %d enemies" % v.call("perfora")
		"sunfire":
			texto = "Explode on hit: %d%% damage in %.1f m" % [v.call("explosion_daño") * 100, v.call("explosion_radio")]
		"storm":
			texto = "Lightning chains to %d enemies (%d%% damage)\nFire rate x%.2f" % [v.call("cadena_saltos"), v.call("cadena_daño") * 100, v.call("cadencia")]
		"dragon":
			texto = "Burns %d%% damage/s for %ds\n+%d%% damage to bosses" % [v.call("quemadura_dps") * 100, v.call("quemadura_seg"), v.call("daño_boss") * 100]
	return texto + "\nDamage x%.2f" % v.call("daño")

static func _mult(mapa : int, i : int) -> float:
	return MAPAS.get(mapa, MAPAS[1])[i]

#horda: el enemigo es miembro de una horda (valores reducidos según HORDA)
static func vida_enemigo(tipo : String, z : float, mapa : int, horda : bool = false) -> int:
	var h = HORDA.vida if horda else 1.0
	return int(ceil(ENEMIGOS[tipo].vida * (1.0 + max(z, 0.0) * VIDA_POR_METRO) * _mult(mapa, 0) * dif().vida * h))

static func daño_enemigo(tipo : String, mapa : int, horda : bool = false) -> int:
	var h = HORDA.daño if horda else 1.0
	return int(ceil(ENEMIGOS[tipo].daño * _mult(mapa, 1) * dif().daño * h))

static func oro_enemigo(tipo : String, mapa : int, horda : bool = false) -> int:
	var h = HORDA.oro if horda else 1.0
	return max(1, int(round(ENEMIGOS[tipo].oro * _mult(mapa, 2) * dif().oro * h)))

static func daño_roca(mapa : int) -> int:
	return int(ceil(ROCA_TROLL_DAÑO * _mult(mapa, 1) * dif().daño))

static func daño_proyectil(tipo : String, mapa : int) -> int:
	return int(ceil(PROYECTIL_DAÑO.get(tipo, ROCA_TROLL_DAÑO) * _mult(mapa, 1) * dif().daño))

#metros por segundo hacia el player (0 = quieto)
static func velocidad_enemigo(tipo : String) -> float:
	return ENEMIGOS.get(tipo, {}).get("velocidad", 0.0)

static func boss_ataque() -> Dictionary:
	return BOSS_ATAQUES.get(dificultad, BOSS_ATAQUES["medium"])

static func boss_vida(mapa : int) -> int:
	return int(BOSS_VIDA * _mult(mapa, 0) * dif().vida)

static func boss_daño(mapa : int) -> int:
	return int(ceil(BOSS_DAÑO * _mult(mapa, 1) * dif().daño))

static func boss_intervalo() -> float:
	return BOSS_INTERVALO * dif().boss_intervalo

static func boss_oro(mapa : int) -> int:
	return int(round(BOSS_ORO * _mult(mapa, 2) * dif().oro))
