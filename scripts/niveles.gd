class_name Niveles

## Diseño de cada mapa para el generador (MapGenerator). Las distancias son metros en z.
## Los valores [inicio, fin] se interpolan a lo largo del recorrido (0 = salida, 1 = boss).
##   largo:      z del boss final
##   inicio:     zona segura al empezar
##   fin_libre:  metros sin enemigos antes del boss
##   separacion: metros entre filas de enemigos [inicio, fin] (se divide por la densidad de la dificultad)
##   por_fila:   máximo de enemigos por fila [inicio, fin] (como mucho 3: siempre quedan 2 carriles libres)
##   tipos:      peso de cada tipo [inicio, fin, desde] (desde = punto del recorrido en el que empieza a salir)
##   jefes:      mini jefes en el carril central (el ogro suelta una puerta de mejora al morir)
##   puertas:    puertas de mejora (la zona alrededor queda libre de enemigos)
##   hordas:     grupos compactos de un tipo débil pegados a una pared (solo si la dificultad
##               tiene hordas > 0, que divide la separación). separacion y desde como arriba;
##               carriles: ancho en carriles [inicio, fin] (2-3); filas: fondo [inicio, fin]
##   columnas:   enemigos normales en fila india en un carril (solo si la dificultad tiene
##               columnas > 0, que divide la separación); el tipo sale de "tipos".
##               separacion y desde como en hordas; largo: enemigos [inicio, fin]
##   boss_ataques: secuencia de ataques del boss final, se repite (tipos en Balance.BOSS_ATAQUES)

const MAPAS = {
	1: {
		"largo": 1000.0,
		"inicio": 25.0,
		"fin_libre": 45.0,
		"separacion": [20.0, 10.0],
		"por_fila": [1, 3],
		#las crías de dragón anuncian la guarida del dragón rojo
		"tipos": {"goblin": [1.0, 0.15, 0.0], "orc": [0.2, 1.0, 0.1], "troll": [0.3, 0.6, 0.45], "whelp": [0.25, 0.5, 0.6]},
		"jefes": {"tipo": "ogre", "z": [250.0, 500.0, 750.0]},
		"puertas": [90.0, 175.0, 330.0, 420.0, 580.0, 670.0, 830.0, 910.0],
		"hordas": {"tipo": "goblin", "separacion": [160.0, 90.0], "desde": 0.12, "carriles": [2, 3], "filas": [3, 5]},
		"columnas": {"separacion": [120.0, 70.0], "desde": 0.1, "largo": [3, 5]},
		"boss_ataques": ["bola", "bola", "barrera"],
	},
	2: {
		"largo": 1000.0,
		"inicio": 25.0,
		"fin_libre": 45.0,
		#los zombis avanzan hacia el player, por eso la separación es mayor de lo que parece
		"separacion": [14.0, 7.0],
		"por_fila": [1, 3],
		#los escupidores lanzan ácido desde lejos
		"tipos": {"zombie": [1.0, 1.0, 0.0], "spitter": [0.15, 0.35, 0.15]},
		"jefes": {"tipo": "brute", "z": [300.0, 600.0, 850.0]},
		"puertas": [80.0, 170.0, 250.0, 380.0, 470.0, 540.0, 680.0, 770.0, 920.0],
		"hordas": {"tipo": "zombie", "separacion": [150.0, 80.0], "desde": 0.1, "carriles": [2, 3], "filas": [3, 5]},
		"columnas": {"separacion": [110.0, 65.0], "desde": 0.1, "largo": [3, 5]},
		"boss_ataques": ["barrera", "bola", "bola", "barrera", "lluvia"],
	},
	#mapa 3: cementerio de noche, no muertos. Los esqueletos avanzan hacia el player, los magos
	#lanzan rayos y los segadores aguantan mucho; el caballero de la muerte es el mini jefe
	3: {
		"largo": 1000.0,
		"inicio": 25.0,
		"fin_libre": 45.0,
		"separacion": [16.0, 8.0],
		"por_fila": [1, 3],
		"tipos": {"skeleton": [1.0, 0.4, 0.0], "skeleton_mage": [0.2, 0.5, 0.1], "reaper": [0.15, 1.0, 0.3]},
		"jefes": {"tipo": "death_knight", "z": [200.0, 400.0, 600.0, 800.0]},
		"puertas": [90.0, 160.0, 300.0, 360.0, 500.0, 560.0, 700.0, 760.0, 900.0],
		"hordas": {"tipo": "skeleton", "separacion": [140.0, 80.0], "desde": 0.08, "carriles": [2, 3], "filas": [4, 5]},
		"columnas": {"separacion": [100.0, 60.0], "desde": 0.08, "largo": [3, 5]},
		"boss_ataques": ["lluvia", "bola", "barrera", "bola"],
	},
}
