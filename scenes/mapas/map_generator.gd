class_name MapGenerator

## Convierte el diseño de un mapa (Niveles.MAPAS) en una lista de spawns ordenada por z:
## [{"tipo": String, "z": float, "x": float}]. Se genera de nuevo en cada partida.

#carriles del camino (x); con 3 enemigos por fila como mucho siempre quedan 2 libres
const CARRILES : Array[float] = [-4.0, -2.0, 0.0, 2.0, 4.0]
const MAX_POR_FILA : int = 3
#metros libres alrededor de puertas y mini jefes
const ZONA_LIBRE : float = 7.0
#separación mínima entre filas: a velocidad base cambiar de carril lleva ~2.7 m de avance
const SEPARACION_MIN : float = 6.0

static func generar(cfg : Dictionary, densidad : float) -> Array:
	var plan : Array = []
	var reservados : Array = cfg.puertas.duplicate()
	for z in cfg.jefes.z:
		reservados.append(z)
		plan.append({"tipo": cfg.jefes.tipo, "z": z, "x": 0.0})

	var largo : float = cfg.largo
	var z : float = cfg.inicio
	var fin : float = largo - cfg.fin_libre
	while z < fin:
		var t = z / largo
		if not _cerca(z, reservados):
			var max_fila = clampi(roundi(lerpf(cfg.por_fila[0], cfg.por_fila[1], t)), 1, MAX_POR_FILA)
			var n = randi_range(1, max_fila)
			var carriles = CARRILES.duplicate()
			carriles.shuffle()
			for i in n:
				plan.append({
					"tipo": _elige_tipo(cfg.tipos, t),
					"z": z + randf_range(-0.5, 0.5),
					"x": carriles[i] + randf_range(-0.5, 0.5),
				})
		var separacion = lerpf(cfg.separacion[0], cfg.separacion[1], t) / densidad
		z += max(separacion * randf_range(0.85, 1.15), SEPARACION_MIN)

	plan.sort_custom(func(a, b): return a.z < b.z)
	return plan

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
