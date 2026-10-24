@tool
class_name MedalIcon extends Control

#medalla dibujada con una estrella; apagada en gris si el logro no está conseguido
@export var encendida : bool = true:
	set(v):
		encendida = v
		queue_redraw()

func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(72, 72)
	resized.connect(queue_redraw)

func _draw() -> void:
	var r = min(size.x, size.y) * 0.5
	var c = size * 0.5
	var borde = Color(0.55, 0.36, 0.05) if encendida else Color(0.2, 0.2, 0.2)
	var fondo = Color(1.0, 0.8, 0.22) if encendida else Color(0.38, 0.38, 0.38)
	var centro = Color(0.93, 0.62, 0.1) if encendida else Color(0.3, 0.3, 0.3)
	var estrella = Color(1.0, 0.95, 0.65) if encendida else Color(0.48, 0.48, 0.48)
	draw_circle(c, r, borde)
	draw_circle(c, r * 0.86, fondo)
	draw_circle(c, r * 0.7, centro)
	var puntos = PackedVector2Array()
	for i in 10:
		var a = -PI / 2 + i * PI / 5
		puntos.append(c + Vector2(cos(a), sin(a)) * r * (0.55 if i % 2 == 0 else 0.23))
	draw_colored_polygon(puntos, estrella)
