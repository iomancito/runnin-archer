class_name Player extends CharacterBody3D

signal position_updated
signal player_dead

@onready var arrow_spawn_point = $Arrow_spawn_mark

@export var normal_arrow : PackedScene

#stats
var stats ={
	"p_speed" : 200,
	"p_side_speed" : 150,
	"p_attack_speed" : 0.7,
	"p_vida" : 10,
	"a_skin" : 1,
	"f_cantidad" : 1,
	"f_velocidad" : 500,
	"f_max_distancia" : 10,
	"f_daño" : 1
}

@export var vida : int = 2

#animatiion_tree
@onready var animation_tree : AnimationTree = $AnimationTree
#modelos de los arcos
@onready var arco1 = $Armature_004/Skeleton3D/BoneAttachment3D/arco1
@onready var arco2 = $Armature_004/Skeleton3D/BoneAttachment3D/arco2
@onready var arco3 = $Armature_004/Skeleton3D/BoneAttachment3D/arco3
@onready var arco4 = $Armature_004/Skeleton3D/BoneAttachment3D/arco4
@onready var arco5 = $Armature_004/Skeleton3D/BoneAttachment3D/arco5

#constantes de los nodos del animation_tree
var JUMP : String = "parameters/archer_jump/request"
var ARCHER_SHOOT : String = "parameters/archer_shoot/request"
var SHOOT : String = "parameters/shoot/request"
var SHOOT_SPEED : String = "parameters/ShootSpeed/scale"
var RUNNING_SPEED : String = "parameters/RunninigSpeed/scale"
var WALKING_SHOOT_SPEED : String = "parameters/WalkingShootSpeed/scale"
var active_bow : int
var velocidad_flechas : Array[int]
#diccionario Nº-arco -> modelo
@onready var bow_dictionay = {
	1 : arco1,
	2 : arco2,
	3 : arco3,
	4 : arco4,
	5 : arco5
}
#variable que controla si está o no habilitado el salto
var action_enabled : bool = true

#para el control táctil
var posicion_inicial_dedo : Vector2
var posicion_final_dedo : Vector2
var index = -1
var direccion :Vector2
#gravedad
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	name = "player"
	velocidad_flechas = generar_secuencia(1000) #velocidad lateral flechas
	cargar_datos_progreso()
	set_bow(1)

func generar_secuencia(x: int) -> Array[int]:
	var resultado : Array[int]
	for i in range(x + 1):
		resultado.append(i)
		if i != 0:  # Evitar añadir -0
			resultado.append(-i)
	return resultado
#lee los datos del progreso del player
func cargar_datos_progreso() -> void:
	$Timer.wait_time = 1 / stats["p_attack_speed"]
	vida = stats["p_vida"]
	$Timer.start()

#######################################################################################################
##		FÍSICAS Y EVENTOS
#######################################################################################################

func _physics_process(delta: float) -> void:
	#emit_signal("position_updated", global_position)
	#gravedad
	velocity.y -= gravity * delta
	#movimiento de avance
	velocity.z = stats["p_speed"] * delta
	#movimiento lateral
	if direccion.x > 0:
		velocity.x = -stats["p_side_speed"] * delta
	elif direccion.x < 0:
		velocity.x = stats["p_side_speed"] * delta
	else:
		velocity.x = 0
	move_and_slide()	

#Control de interacción con la pantalla
func _input(event: InputEvent) -> void:
	#Pantalla es tocada
	if event is InputEventScreenTouch and event.is_pressed() and index == -1:
		posicion_inicial_dedo = event.position
		index = event.index
	#Dedo es arrastrado
	if event is InputEventScreenDrag and index == event.index:
		posicion_final_dedo = event.position
		direccion = posicion_inicial_dedo.direction_to(posicion_final_dedo)
	#Pantalla deja de ser tocada
	if event is InputEventScreenTouch and !event.is_pressed():
		#posicion_inicial = Vector2.ZERO
		direccion = Vector2.ZERO
		index = -1

		
#######################################################################################################
##								PARTE RELATIVA AL ANIMATION_TREE CON LOS MOVIMIENTOS DEL MODELO 3D
#######################################################################################################

##Accede al AnimationTree para gestionar la animación de salto
#func jump() ->void:
	#animation_tree.set(JUMP, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	#if is_on_floor():
		#action_enabled = false
		#velocity.y = jump_impulse
		#

#Accede al AnimationTree para gestionar la animación de disparo
func shoot() -> void:
	animation_tree.set(ARCHER_SHOOT, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	animation_tree.set(SHOOT, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
#se llama al finalizar la animación de salto para habilitarlo de nuevo
func animation_finished() -> void:
	action_enabled = true	

#incrementa la velocidad de movimiento de la animación
#s es el ratio, debería ser 1.01 o similar	
func set_running_speed(s : float) -> void:
	var running = animation_tree.get(RUNNING_SPEED)
	animation_tree.set(RUNNING_SPEED, running * s)

#incrementa la velocidad de ataque de la animación
#incrementa la velocidad del paso de la animación
#s es el ratio, debería ser 1.01 o similar, proporcional al incremento de  velocidad de ataque
func set_attack_speed(s : float) -> void:
	var shoot = animation_tree.get(SHOOT_SPEED)
	animation_tree.set(SHOOT_SPEED, shoot * s)
	var walking_shoot = animation_tree.get(WALKING_SHOOT_SPEED)
	animation_tree.set(WALKING_SHOOT_SPEED, walking_shoot * s)

#######################################################################################################
##								CAMBIO DE MODELO DEL ARCO

func set_bow(n : int) -> void:
	if active_bow > 0 and active_bow < 6:
		bow_dictionay[active_bow].hide()
	active_bow = n
	bow_dictionay[active_bow].show()

#######################################################################################################
##			INCREMENTOS DE ESTADÍSTICAS DEL PLAYER
#######################################################################################################
#incrementa la velocidad de movimiento
# s el valor a incrementar
#incrementa la velocidad de la animación proporcionalmente speed/old_speed
func increase_move_speed(s : float) -> void:
	var old_speed = stats["p_speed"]
	stats["p_speed"] += s
	set_running_speed(stats["p_speed"]/old_speed)

#incrementa la velocidad de ataque, s es la frecuencia
func increase_attack_speed(s : float = 0.1) -> void:
	var old_speed = stats["p_attack_speed"]
	stats["p_attack_speed"] += s
	$Timer.wait_time = 1 / stats["p_attack_speed"]
	set_attack_speed(stats["p_attack_speed"] / old_speed)
#incremeta el daño de la flecha
func increase_arrow_damage(d :int = 1) -> void:
	stats["f_daño"] += d
	
#incrementa la velocidad de movimiento lateral
func increas_side_speed(s : float = 5) -> void:
	stats["p_side_speed"] += s

#incrementa la velocidad de la flecha
func increase_arrow_speed(s : float = 10) -> void:
	stats["f_velocidad"] += s
#incrementa la distancia máxima de la flecha
func increase_arrow_distance(s : float = 0.2) -> void:
	stats["f_max_distancia"] += s

func increase_arrow_number(i : int = 1) -> void:
	stats["f_cantidad"] +=1
	
#reduce la vida del player
func recibe_daño(d : int) -> void:
	vida -= d
	if vida <= 0:
		velocity = Vector3.ZERO
		await get_tree().create_timer(0.3).timeout
		fin_partida()
		
#Realiza el araque, instancir flecha y demás
func attack() -> void:
	for i in range (0, stats["f_cantidad"]):
		var flecha_instancia = normal_arrow.instantiate()
		get_parent().find_child("ArrowContainer").add_child(flecha_instancia)
		flecha_instancia.global_position = arrow_spawn_point.global_position
		flecha_instancia.velocity.x = velocidad_flechas[i] * 0.2
		flecha_instancia.inicia(self)

func fin_partida() ->void:
	player_dead.emit()
	
func _on_timer_timeout() -> void:
	shoot()
