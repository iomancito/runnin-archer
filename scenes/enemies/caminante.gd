class_name Caminante extends Enemy

## Enemigo con una animación en bucle que avanza hacia el player a la velocidad de su tipo
## (Balance.ENEMIGOS[tipo].velocidad; 0 = quieto). Si tiene animación de "cerca", la hace
## una vez cuando el player se acerca (el caballero de la muerte ruge).

@export var anim : String = "walk"
#velocidad de la animación (ajusta el paso a la velocidad real)
@export var anim_escala : float = 1.0
@export var anim_cerca : String = ""
#metros por delante del player a los que hace la animación de "cerca"
@export var distancia_cerca : float = 12.0

var _anim : AnimationPlayer
var _cerca_hecha : bool = false

func _ready() -> void:
	super()
	_anim = find_child("AnimationPlayer", true, false)
	if _anim and _anim.has_animation(anim):
		_anim.get_animation(anim).loop_mode = Animation.LOOP_LINEAR
		_anim.play(anim, -1, anim_escala)
		#cada uno empieza en un punto distinto del paso
		_anim.seek(randf() * _anim.current_animation_length, true)
		_anim.animation_finished.connect(func(_n): _anim.play(anim, 0.3, anim_escala))

func _physics_process(_delta : float) -> void:
	var v = Balance.velocidad_enemigo(tipo)
	if v > 0.0:
		velocity.z = -v
		move_and_slide()
	if anim_cerca != "" and not _cerca_hecha and is_instance_valid(Progreso.player):
		if global_position.z - Progreso.player.global_position.z < distancia_cerca:
			_cerca_hecha = true
			_anim.play(anim_cerca, 0.3)
