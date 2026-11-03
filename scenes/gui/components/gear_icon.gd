@tool
class_name GearIcon extends Control

#engranaje de ajustes dibujado, evita depender de una textura
#opaco: dientes y aro se solapan y con alfa se notaría la junta
@export var color : Color = Color(1, 1, 1) :
	set(c):
		color = c
		queue_redraw()
const DIENTES : int = 8

func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(48, 48)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var r = min(size.x, size.y) * 0.5
	var c = size * 0.5
	var exterior = r
	var interior = r * 0.74
	var hueco = r * 0.3
	var paso = TAU / DIENTES
	#dientes: trapecios más anchos en la base, metidos un poco en el aro para que no quede junta
	for i in DIENTES:
		var a = i * paso
		draw_colored_polygon(PackedVector2Array([
			c + Vector2.from_angle(a - paso * 0.28) * interior * 0.9,
			c + Vector2.from_angle(a - paso * 0.16) * exterior,
			c + Vector2.from_angle(a + paso * 0.16) * exterior,
			c + Vector2.from_angle(a + paso * 0.28) * interior * 0.9,
		]), color)
	#aro con el agujero central transparente
	draw_arc(c, (interior + hueco) * 0.5, 0, TAU, 40, color, interior - hueco, true)
