extends Mapa

#provisional: usa los enemigos del mapa 1 hasta que tenga los suyos
func _init() -> void:
	numero = 3
	boss_name = "Ancient Dragon"

func escena_de(tipo : String) -> PackedScene:
	match tipo:
		"orc": return enemies[1]
		"troll": return enemies[2]
		"ogre": return boss[0]
	return enemies[0]
