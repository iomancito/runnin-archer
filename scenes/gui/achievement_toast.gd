class_name AchievementToast extends Control

## Aviso arriba de la pantalla al desbloquear un logro; si llegan varios a la vez van en cola.
## Funciona en pausa (cuelga del HUD) y no bloquea los toques.

const DURACION : float = 2.5
#con avisos en cola se acorta cada uno
const DURACION_COLA : float = 1.3
const ENTRADA : float = 0.3

var cola : Array[String] = []
var mostrando : bool = false
var panel : PanelContainer
var medalla : MedalIcon
var nombre : Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = PanelContainer.new()
	panel.theme_type_variation = &"PanelContainer"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	panel.add_child(fila)
	medalla = MedalIcon.new()
	medalla.custom_minimum_size = Vector2(64, 64)
	medalla.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(medalla)
	var textos = VBoxContainer.new()
	textos.add_theme_constant_override("separation", 0)
	fila.add_child(textos)
	var titulo = Label.new()
	titulo.text = "Achievement unlocked!"
	titulo.theme_type_variation = &"SmallLabel"
	textos.add_child(titulo)
	nombre = Label.new()
	nombre.theme_type_variation = &"GoldLabel"
	nombre.add_theme_font_size_override("font_size", 34)
	textos.add_child(nombre)
	for n in [fila, medalla, textos, titulo, nombre]:
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.hide()
	Logros.desbloqueado.connect(_on_desbloqueado)

func _on_desbloqueado(id : String) -> void:
	cola.append(id)
	if not mostrando:
		_siguiente()

func _siguiente() -> void:
	if cola.is_empty():
		mostrando = false
		panel.hide()
		return
	mostrando = true
	nombre.text = Logros.por_id[cola.pop_front()].nombre
	panel.show()
	panel.reset_size()
	await get_tree().process_frame
	var x = (size.x - panel.size.x) * 0.5
	var arriba = 48.0
	panel.position = Vector2(x, -panel.size.y)
	var tw = create_tween()
	tw.tween_property(panel, "position:y", arriba, ENTRADA).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(DURACION_COLA if not cola.is_empty() else DURACION)
	tw.tween_property(panel, "position:y", -panel.size.y, ENTRADA).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(_siguiente)
