class_name DragonNegro extends Boss

## Dragón negro (mapa 2): fuego violeta. Sus ataques se hacen en tools/dragon_negro.py.

func _init() -> void:
	#"spit" abre la boca a los 0,55 s y "breath" a los 0,85 s (ANIMS de tools/dragon_negro.py)
	anim_ataques = {"bola": ["spit", 0.55], "barrera": ["breath", 0.85], "lluvia": ["spit", 0.55]}
	hueso_boca = "Bone"
	boca_adelante = 0.6
	estilo = Proyectil.Estilo.FUEGO_OSCURO
