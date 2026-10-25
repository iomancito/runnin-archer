class_name DragonEsqueleto extends Boss

## Dragón esqueleto (mapa 3): escupe almas. Modelo y animaciones de skeleton_dragon.glb.

func _init() -> void:
	#segundo de cada animación en el que lanza la cabeza (medido)
	anim_ataques = {"bola": ["breath", 1.05], "barrera": ["rear_breath", 1.6], "lluvia": ["roar", 0.85]}
	hueso_boca = "Bip001 Head"
	boca_adelante = 0.9
	estilo = Proyectil.Estilo.ALMAS
