class_name ZombiEscupidor extends Lanzador

## Zombi quieto que escupe ácido (mapa 2): al disparar le sale un chorro de gotas de la boca hacia
## el player y un proyectil de ácido cae en la marca del suelo (ver Lanzador y Acido).
## Usa el modelo del zombi de la espada con un tinte verde para distinguirlo.

#segundos que dura el chorro de la boca
const CHORRO_SEG : float = 0.45

var _chorro : GPUParticles3D

func _ready() -> void:
	super()
	_chorro = Acido.chorro()
	add_child(_chorro)
	for malla in find_children("*", "MeshInstance3D", true, false):
		malla.material_overlay = Acido.tinte()

func _dispara() -> void:
	var p = Progreso.player
	if is_instance_valid(p):
		_chorro.global_position = _origen()
		_chorro.look_at(p.global_position + Vector3.UP * 0.5, Vector3.UP, true)
		_chorro.emitting = true
		get_tree().create_timer(CHORRO_SEG, false).timeout.connect(func(): _chorro.emitting = false)
	super()
