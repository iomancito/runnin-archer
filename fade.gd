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
