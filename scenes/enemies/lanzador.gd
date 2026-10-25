class_name Lanzador extends Enemy

## Enemigo quieto que dispara al player cuando lo tiene delante (Balance.LANZADOR): el proyectil
## marca en el suelo dónde caerá (donde estará el player si sigue recto) y hay que apartarse.

@export var anim_reposo : String = "idle"
@export var anim_ataque : String = ""
#segundo de la animación de ataque en el que sale el proyectil
@export var retardo : float = 0.5
#de dónde sale: hueso y metros por delante de él
@export var hueso : String = ""
@export var adelante : float = 0.3
@export var estilo : Proyectil.Estilo = Proyectil.Estilo.FUEGO
@export var escala_proyectil : float = 0.6

var _anim : AnimationPlayer
var _esqueleto : Skeleton3D
var _hueso : int = -1
var _disparos : int = 0
var _recarga : float = 0.0

const ARCO : float = 1.5

func _ready() -> void:
	super()
	_anim = find_child("AnimationPlayer", true, false)
	_esqueleto = find_child("Skeleton3D", true, false)
	if _esqueleto and hueso != "":
		_hueso = _esqueleto.find_bone(hueso)
	if _anim and _anim.has_animation(anim_reposo):
		_anim.get_animation(anim_reposo).loop_mode = Animation.LOOP_LINEAR
		_anim.play(anim_reposo)
		_anim.seek(randf() * _anim.current_animation_length, true)
		_anim.animation_finished.connect(func(_n): _anim.play(anim_reposo, 0.3))

func _physics_process(delta : float) -> void:
	_recarga -= delta
	var p = Progreso.player
	if _recarga > 0.0 or _disparos >= Balance.LANZADOR.disparos or vida <= 0 or not is_instance_valid(p) or p.is_dead:
		return
	var distancia = global_position.z - p.global_position.z
	if distancia > 2.0 and distancia < Balance.LANZADOR.distancia:
		_disparos += 1
		_recarga = Balance.LANZADOR.recarga
		_dispara()

func _dispara() -> void:
	if _anim and _anim.has_animation(anim_ataque):
		_anim.play(anim_ataque, 0.2)
	await get_tree().create_timer(retardo, false).timeout
	var p = Progreso.player
	if vida <= 0 or not is_inside_tree() or not is_instance_valid(p) or p.is_dead:
		return
	var aviso = Balance.LANZADOR.aviso
	#donde estará si sigue recto (no se adelanta a los movimientos laterales)
	var destino = p.global_position + Vector3(0, 0, p.velocity.z * aviso)
	#no cae detrás del lanzador
	destino.z = min(destino.z, global_position.z - 1.0)
	Proyectil.lanzar(get_parent(), _origen(), destino, aviso, Balance.daño_proyectil(tipo, mapa), estilo,
		Proyectil.Forma.CIRCULO, Balance.LANZADOR.radio, ARCO, escala_proyectil)

func _origen() -> Vector3:
	if _esqueleto and _hueso >= 0:
		var t = _esqueleto.global_transform * _esqueleto.get_bone_global_pose(_hueso)
		return t.origin + Vector3(0, 0, -adelante)
	return global_position + Vector3(0, 1.2, -0.5)
