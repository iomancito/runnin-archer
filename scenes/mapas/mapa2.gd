extends Mapa

#escala del zombi grande (mini jefe)
const ESCALA_BRUTE : float = 1.6

func _init() -> void:
	numero = 2
	boss_name = "Black Dragon"

#tres modelos de zombi distintos al azar
func escena_de(_tipo : String) -> PackedScene:
	return enemies.pick_random()

func prepara(enemigo : Enemy, tipo : String) -> void:
	if tipo == "brute":
		enemigo.scale = Vector3.ONE * ESCALA_BRUTE
