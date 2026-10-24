extends Control

var fade = false

func fade_in(t : float = 1) -> void:
	show()
	var tw = get_tree().create_tween()
	await tw.tween_property($ColorRect, "modulate:a", 1, t).finished
	
func fade_out(t : float = 1) -> void:
	var tw = get_tree().create_tween()
	await tw.tween_property($ColorRect, "modulate:a", 0, t).finished
	hide()

func fade_in_out(t : float = 0.1, t2 : float = 1) -> void:
	fade_in(t)
	await get_tree().create_timer(t).timeout
	fade_out(t2)

#pantalla negra inmediata con un texto (pantalla de carga)
func mostrar_negro(texto : String = "") -> void:
	show()
	$ColorRect.modulate.a = 1.0
	set_texto(texto)

func set_texto(texto : String) -> void:
	$ColorRect/Texto.text = texto
