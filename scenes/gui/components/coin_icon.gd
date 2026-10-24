@tool
class_name CoinIcon extends Control

#moneda dibujada, evita depender de una textura
func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(40, 40)
	resized.connect(queue_redraw)

func _draw() -> void:
	var r = min(size.x, size.y) * 0.5
	var c = size * 0.5
	draw_circle(c, r, Color(0.55, 0.36, 0.05))
	draw_circle(c, r * 0.86, Color(1.0, 0.8, 0.22))
	draw_circle(c, r * 0.6, Color(0.93, 0.66, 0.12))
	draw_arc(c, r * 0.6, 0, TAU, 24, Color(1.0, 0.92, 0.55), max(1.0, r * 0.1), true)
