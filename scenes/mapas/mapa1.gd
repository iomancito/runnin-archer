extends Mapa

func _init() -> void:
	numero = 1
	boss_name = "Red Dragon"

func escena_de(tipo : String) -> PackedScene:
	match tipo:
		"orc": return enemies[1]
		"troll": return enemies[2]
		"whelp": return enemies[3]
		"ogre": return boss[0]
	return enemies[0]
