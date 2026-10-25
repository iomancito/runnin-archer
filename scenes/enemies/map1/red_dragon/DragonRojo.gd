class_name DragonRojo extends Boss

## Dragón rojo (mapa 1). Modelo y animaciones de red_dragon.glb (ver tools/importar_modelos.py).

func _init() -> void:
	#segundo de cada animación en el que lanza la cabeza con la boca abierta (medido)
	anim_ataques = {"bola": ["bite", 0.55], "barrera": ["breath", 1.05], "lluvia": ["roar", 0.8]}
	hueso_boca = "ValveBiped.Bip01_breath"
	boca_adelante = 0.4
	estilo = Proyectil.Estilo.FUEGO
