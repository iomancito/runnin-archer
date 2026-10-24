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
	"zombie": {"vida": 4, "daño": 2, "oro": 1},
	"brute": {"vida": 25, "daño": 6, "oro": 8}, #zombi grande, mini jefe del mapa 2
}
const ROCA_TROLL_DAÑO = 4
#la vida crece con la distancia: x1 al inicio, x3.5 a los 1000 m
const VIDA_POR_METRO = 1.0 / 400.0
#multiplicadores por mapa: [vida, daño, oro]
const MAPAS = {1: [1.0, 1.0, 1.0], 2: [3.0, 1.5, 1.5], 3: [7.0, 2.0, 2.0]}

#--- Dificultad: multiplica vida, daño, densidad de enemigos y oro (también de los bosses) ---
const DIFICULTADES = {
	"easy": {"nombre": "Easy", "vida": 0.6, "daño": 0.5, "densidad": 0.75, "oro": 0.6, "boss_intervalo": 1.3},
	"medium": {"nombre": "Medium", "vida": 1.0, "daño": 1.0, "densidad": 1.0, "oro": 1.0, "boss_intervalo": 1.0},
	"hard": {"nombre": "Hard", "vida": 1.7, "daño": 1.5, "densidad": 1.25, "oro": 1.6, "boss_intervalo": 0.9},
	"hell": {"nombre": "Hell", "vida": 3.0, "daño": 2.5, "densidad": 1.5, "oro": 2.5, "boss_intervalo": 0.75},
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

#--- Tienda: nombre (clave de guardado), título, formato, stat, incremento, costes por nivel ---
static func tienda() -> Array:
	return [
		["damage", "Damage", "%d", "f_daño", 1, costes(12, 1.4, 10)],
		["attack_speed", "Fire Rate", "%.1f/s", "p_attack_speed", 0.1, costes(12, 1.4, 10)],
		["arrow_number", "Arrows", "%d", "f_cantidad", 1, [50, 150, 400, 900]],
		["vida", "Max HP", "%d", "p_vida", 5, costes(8, 1.4, 10)],
		["range", "Range", "%d m", "f_max_distancia", 2, costes(8, 1.4, 10)],
		["dodge", "Dodge Speed", "%d", "p_side_speed", 10, costes(6, 1.4, 10)],
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

static func costes(base : float, crecimiento : float, niveles : int) -> Array[int]:
	var r : Array[int] = []
	for i in niveles:
		r.append(int(round(base * pow(crecimiento, i))))
	return r

static func _mult(mapa : int, i : int) -> float:
	return MAPAS.get(mapa, MAPAS[1])[i]

static func vida_enemigo(tipo : String, z : float, mapa : int) -> int:
	return int(ceil(ENEMIGOS[tipo].vida * (1.0 + max(z, 0.0) * VIDA_POR_METRO) * _mult(mapa, 0) * dif().vida))

static func daño_enemigo(tipo : String, mapa : int) -> int:
	return int(ceil(ENEMIGOS[tipo].daño * _mult(mapa, 1) * dif().daño))

static func oro_enemigo(tipo : String, mapa : int) -> int:
	return max(1, int(round(ENEMIGOS[tipo].oro * _mult(mapa, 2) * dif().oro)))

static func daño_roca(mapa : int) -> int:
	return int(ceil(ROCA_TROLL_DAÑO * _mult(mapa, 1) * dif().daño))

static func boss_vida(mapa : int) -> int:
	return int(BOSS_VIDA * _mult(mapa, 0) * dif().vida)

static func boss_daño(mapa : int) -> int:
	return int(ceil(BOSS_DAÑO * _mult(mapa, 1) * dif().daño))

static func boss_intervalo() -> float:
	return BOSS_INTERVALO * dif().boss_intervalo

static func boss_oro(mapa : int) -> int:
	return int(round(BOSS_ORO * _mult(mapa, 2) * dif().oro))
