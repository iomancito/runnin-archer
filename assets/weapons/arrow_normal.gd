class_name Normal_Arrow extends CharacterBody3D

var player : Player
@export var speed : float
@export var distancia_max : float
@export var daño : int = 1
var posicion_inicial : float

func inicia(p : Player) -> void:
	player = p
	speed = p.stats["f_velocidad"]
	daño = p.stats["f_daño"]
	distancia_max = p.stats["f_max_distancia"]
	posicion_inicial = global_position.z

func _physics_process(delta: float) -> void:
	velocity.z = speed * delta
	move_and_slide()
	
func _process(delta: float) -> void:
	if global_position.z - posicion_inicial > distancia_max:
		queue_free()
		
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Enemy :
		body.recibe_daño(daño)
		queue_free()
