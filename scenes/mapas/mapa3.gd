extends Mapa

func _init() -> void:
	numero = 3
	boss_name = "Bone Dragon"

func escena_de(tipo : String) -> PackedScene:
	match tipo:
		"skeleton_mage": return enemies[1]
		"reaper": return enemies[2]
		"death_knight": return boss[0]
	return enemies[0]
