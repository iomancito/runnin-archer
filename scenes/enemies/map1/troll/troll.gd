class_name Troll	 extends Enemy

@export var projectile_scene : PackedScene = load("res://scenes/otros/Piedra.tscn")
# Configuración de parámetros
@export var launch_speed: float = 100.0         # Velocidad inicial del proyectil
@export var gravity: float = 9.8              # Gravedad (m/s²)
@export var prediction_steps: int = 100       # Iteraciones para cálculo predictivo
@export var max_prediction_time: float = 5.0  # Tiempo máximo de predicción

@onready var player  # Ruta al jugador

func throw_projectile():
	player = Progreso.player
	if not is_instance_valid(player):
		return
	var proyectile_pos = $Armature/Skeleton3D/BoneAttachment3D/Pebble_Square_32.global_position
	var target_pos = player.global_position
	var target_vel = player.get_velocity()
	var launch_vel = calculate_launch_velocity(proyectile_pos, target_pos, target_vel)

	if launch_vel != Vector3.ZERO:
		var projectile = projectile_scene.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = proyectile_pos
		projectile.set_velocity(launch_vel/15) 
		projectile.daño = Balance.daño_roca(mapa)

func calculate_launch_velocity(start_pos: Vector3, target_pos: Vector3, target_vel: Vector3) -> Vector3:
	var delta = target_pos - start_pos
	var best_velocity = Vector3.ZERO
	var best_error = INF

	# Búsqueda predictiva iterativa
	for i in range(1, prediction_steps + 1):
		var prediction_time = max_prediction_time * i / prediction_steps
		var future_pos = target_pos + target_vel * prediction_time

		# Calcular componentes de velocidad
		var horizontal_dir = Vector3(future_pos.x - start_pos.x, 0, future_pos.z - start_pos.z).normalized()
		var horizontal_dist = start_pos.distance_to(Vector3(future_pos.x, start_pos.y, future_pos.z))
		var vertical_dist = future_pos.y - start_pos.y

		# Ecuación de movimiento vertical: y = v0_y * t - 0.5 * g * t²
		var v0_y = (vertical_dist + 0.5 * gravity * prediction_time * prediction_time) / prediction_time

		# Velocidad horizontal necesaria
		var v0_horizontal = horizontal_dist / prediction_time

		# Verificar si la velocidad total es válida
		var total_speed = sqrt(v0_horizontal * v0_horizontal + v0_y * v0_y)
		var speed_error = abs(total_speed - launch_speed)

		if speed_error < best_error && total_speed <= launch_speed * 1.1:
			best_error = speed_error
			best_velocity = horizontal_dir * v0_horizontal + Vector3.UP * v0_y
	
	return best_velocity	
