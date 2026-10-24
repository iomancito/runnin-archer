class_name MapGenerator

## Convierte el diseño de un mapa (Niveles.MAPAS) en una lista de spawns ordenada por z:
## [{"tipo": String, "z": float, "x": float, "horda": bool}]. Se genera de nuevo en cada partida.

#carriles del camino (x); con 3 enemigos por fila como mucho siempre quedan 2 libres
const CARRILES : Array[float] = [-4.0, -2.0, 0.0, 2.0, 4.0]
const MAX_POR_FILA : int = 3
#metros libres alrededor de puertas y mini jefes
const ZONA_LIBRE : float = 7.0
#separación mínima entre filas: a velocidad base cambiar de carril lleva ~2.7 m de avance
const SEPARACION_MIN : float = 6.0
#distancia entre los miembros de una horda (x, z) y margen fuera de sus carriles extremos
const HORDA_ESPACIO : Vector2 = Vector2(1.3, 1.6)
const HORDA_MARGEN : float = 0.6

#hordas: multiplicador de frecuencia de hordas de la dificultad (0 = sin hordas)
static func generar(cfg : Dictionary, densidad : float, hordas : float = 0.0) -> Array:
	var plan : Array = []
	var reservados : Array = cfg.puertas.duplicate()
	for z in cfg.jefes.z:
		reservados.append(z)
		plan.append({"tipo": cfg.jefes.tipo, "z": z, "x": 0.0, "horda": false})

	var largo : float = cfg.largo
	var fin : float = largo - cfg.fin_libre
	#tramos [inicio, fin] ocupados por hordas: las filas normales no entran en ellos
	var tramos : Array = []
	if hordas > 0.0 and cfg.has("hordas"):
		tramos = _hordas(cfg, hordas, reservados, fin, plan)

	var z : float = cfg.inicio
	while z < fin:
		var t = z / largo
		if not _cerca(z, reservados) and not _en_tramo(z, tramos):
			var max_fila = clampi(roundi(lerpf(cfg.por_fila[0], cfg.por_fila[1], t)), 1, MAX_POR_FILA)
			var n = randi_range(1, max_fila)
			var carriles = CARRILES.duplicate()
			carriles.shuffle()
			for i in n:
				plan.append({
					"tipo": _elige_tipo(cfg.tipos, t),
					"z": z + randf_range(-0.5, 0.5),
					"x": carriles[i] + randf_range(-0.5, 0.5),
					"horda": false,
				})
		var separacion = lerpf(cfg.separacion[0], cfg.separacion[1], t) / densidad
		z += max(separacion * randf_range(0.85, 1.15), SEPARACION_MIN)

	plan.sort_custom(func(a, b): return a.z < b.z)
	return plan

#coloca las hordas en el plan y devuelve los tramos que ocupan. Cada horda va pegada a una
#pared (izquierda o derecha al azar), así quedan libres al menos 2 carriles contiguos
static func _hordas(cfg : Dictionary, frecuencia : float, reservados : Array, fin : float, plan : Array) -> Array:
	var h : Dictionary = cfg.hordas
	var largo : float = cfg.largo
	var tramos : Array = []
	var z : float = max(cfg.inicio, h.desde * largo)
	while z < fin:
		var t = z / largo
		var carriles = clampi(roundi(lerpf(h.carriles[0], h.carriles[1], t)), 1, CARRILES.size() - 2)
		var filas = maxi(roundi(lerpf(h.filas[0], h.filas[1], t)), 1)
		var fondo = (filas - 1) * HORDA_ESPACIO.y
		#la horda entera debe quedar lejos de puertas y mini jefes y antes del final libre
		if z + fondo < fin and not _cerca(z, reservados) and not _cerca(z + fondo, reservados):
			var izquierda = randi_range(0, 1) == 0
			var x_ini = CARRILES[0] - HORDA_MARGEN if izquierda else CARRILES[CARRILES.size() - carriles] - HORDA_MARGEN
			var ancho = (carriles - 1) * (CARRILES[1] - CARRILES[0]) + HORDA_MARGEN * 2.0
			var por_fila = int(ancho / HORDA_ESPACIO.x) + 1
			var paso_x = ancho / (por_fila - 1)
			for f in filas:
				for c in por_fila:
					plan.append({
						"tipo": h.tipo,
						"z": z + f * HORDA_ESPACIO.y + randf_range(-0.2, 0.2),
						"x": x_ini + c * paso_x + randf_range(-0.2, 0.2),
						"horda": true,
					})
			tramos.append([z, z + fondo])
			z += fondo
		z += lerpf(h.separacion[0], h.separacion[1], t) / frecuencia * randf_range(0.85, 1.15)
	return tramos

#z dentro de un tramo de horda o a menos de ZONA_LIBRE de él
static func _en_tramo(z : float, tramos : Array) -> bool:
	for tr in tramos:
		if z > tr[0] - ZONA_LIBRE and z < tr[1] + ZONA_LIBRE:
			return true
	return false

static func _cerca(z : float, reservados : Array) -> bool:
	for r in reservados:
		if absf(z - r) < ZONA_LIBRE:
			return true
	return false

#elige un tipo al azar según su peso en este punto del recorrido
static func _elige_tipo(tipos : Dictionary, t : float) -> String:
	var pesos := {}
	var total := 0.0
	for tipo in tipos:
		var d = tipos[tipo]
		var p = 0.0 if t < d[2] else lerpf(d[0], d[1], t)
		pesos[tipo] = p
		total += p
	var r = randf() * total
	for tipo in pesos:
		r -= pesos[tipo]
		if r <= 0.0:
			return tipo
	return tipos.keys()[0]
