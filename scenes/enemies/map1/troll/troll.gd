class_name Troll extends Lanzador

## Troll del mapa 1: lanza la piedra que lleva en la mano con las reglas de todos los Lanzador.
## Su única animación es la del lanzamiento (suelta la piedra a los 0,9 s); quieto, se queda
## en su primer fotograma.

func _init() -> void:
	anim_reposo = ""
	anim_ataque = "Armature|mixamo_com|Layer0"
	retardo = 0.9
	hueso = "mixamorig_RightHandIndex1"
	adelante = 0.0
	estilo = Proyectil.Estilo.PIEDRA
	escala_proyectil = 1.0
