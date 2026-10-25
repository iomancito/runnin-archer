extends Mapa

func _init() -> void:
	numero = 2
	boss_name = "Black Dragon"

#tres modelos de zombi distintos al azar; el mini jefe es el zombi gordo
func escena_de(tipo : String) -> PackedScene:
	if tipo == "brute":
		return boss[0]
	return enemies.pick_random()
