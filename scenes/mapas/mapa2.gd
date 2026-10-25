extends Mapa

func _init() -> void:
	numero = 2
	boss_name = "Black Dragon"

#cargado por código: también está en export_files del preset Android
const ESCUPIDOR : PackedScene = preload("res://scenes/enemies/map2/zombi_escupidor.tscn")

#tres modelos de zombi distintos al azar; el mini jefe es el zombi gordo
func escena_de(tipo : String) -> PackedScene:
	if tipo == "brute":
		return boss[0]
	if tipo == "spitter":
		return ESCUPIDOR
	return enemies.pick_random()
