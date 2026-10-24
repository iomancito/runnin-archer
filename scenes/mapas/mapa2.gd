extends Node3D

#estructuras laterales
@export var left : Array[PackedScene]
@export var right : Array[PackedScene]
#array enemigos
@export var enemies : Array[PackedScene]
#boss intermedio
@export var boss : Array[PackedScene]
#boss final
@export var final : PackedScene
#paneles
@export var panel : PackedScene
#spawn del player
@onready var spawn_point = $Suelo/Spawn
@onready var path = $Suelo/Path3D

var spawn_points: PackedVector3Array  # Puntos de spawn a lo largo del camino
var origen : float = 30
var dragon_negro

func _ready() -> void:
	#generate_spawn_points()
	instancia_laterales()
	instancia_enemigos()
	instancia_paneles()
	
func generate_spawn_points():
	var curve = path.curve
	# Crear una curva con 2 puntos (inicio y fin)
	curve.clear_points()
	curve.add_point(Vector3(0, 0, 0))  # Punto inicial
	curve.add_point(Vector3(0, 0, 10000))  # Punto final (10km)
	# Paso crítico en Godot 4: Hornear la curva para muestreo preciso
	curve.bake_interval = 0.1  # Precisión del muestreo (menos = más preciso)
	curve.sample_baked()

	# Generar puntos cada 50 metros
	for distance in range(20, curve.get_baked_length(), 15):
		var pos = curve.sample_baked(distance)
		spawn_points.append(pos)
	
func get_spawn_point() -> Vector3:
	return spawn_point.global_position

func instancia_laterales() -> void:
	for i in range (0,100):
		var instancia_R = right[randi_range(0,2)].instantiate()
		var instancia_L = left[randi_range(0,2)].instantiate()
		$Suelo/Laterales.add_child(instancia_R)
		instancia_R.global_position = Vector3(0,0,i*origen)
		$Suelo/Laterales.add_child(instancia_L)
		instancia_L.global_position = Vector3(0,0,i*origen)

func instancia_paneles() -> void:
	for i in range(1,9):
		var instancia = panel.instantiate()
		$Suelo/Paneles.add_child(instancia)
		instancia.global_position.z = i * 50
		
		
func instancia_enemigos() -> void:
	for i in range(1, 180):
		if i != 100:
			var instancia = enemies[randi_range(0, enemies.size()-1)].instantiate()
			instancia.name = "zombie" + str(i)
			$Suelo/Enemigos.add_child(instancia)
			instancia.global_position.z = i * 5
			instancia.global_position.x = randf_range(-4,4)
			instancia.set_vida(5 + int(i/3))
			instancia.update_hp()

	#for i in range(1,9):
		#var instancia = boss[0].instantiate()
		#instancia.name = "boss" + str(i)
		#$Suelo/Enemigos.add_child(instancia)
		#instancia.global_position.z = i * 90
		#instancia.set_vida(i + i * 25)
		#instancia.update_hp()
		
	dragon_negro = final.instantiate()
	dragon_negro.name = "boss_final"
	$Suelo/Enemigos.add_child(dragon_negro)
	dragon_negro.global_position.z = 1000
	dragon_negro.set_vida(500)
	dragon_negro.update_hp()

#nombre que muestra la barra de vida del boss
var boss_name : String = "Black Dragon"

func get_boss() -> Enemy:
	return dragon_negro

func set_boss(main : Node) -> void:
	dragon_negro.connect("muere_boss", main.muere_boss)
