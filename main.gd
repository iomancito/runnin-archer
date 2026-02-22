class_name Main extends Node3D

signal mapa_cargado

@export var player_scene : PackedScene

@onready var map_container = $MapContainer
@onready var enemies_container = $EnemiesContainer
@onready var arrow_container = $ArrowContainer
@onready var hud = $HUD
@onready var menu_principal = $HUD/ColorRect
@onready var menu_mejoras = $HUD/Mejoras
@onready var fade = %fade

var player
var partida_iniciada : bool = false

var current_map: Node3D
# En vez de índices, almacena referencias directas:
var spawned_enemies: Array[Node3D] = []

func _ready() -> void:
	fade.fade_in_out(0.1, 2)
	
func iniciar_partida() -> void:
	#load_map(3)
	show_game()
	
func load_map(map_index: int):
	# Eliminar mapa anterior
	if current_map != null:
		current_map.queue_free()

	# Cargar nuevo mapa (ej: map1.tscn, map2.tscn)
	var map_scene = load("res://scenes/mapas/mapa{index}.tscn".format({"index": map_index}))
	current_map = map_scene.instantiate()
	map_container.add_child(current_map)
	spawn_player()
	current_map.call_deferred("set_boss", self)
	
	
func muere_boss(s : Node3D) -> void :
	s.disconnect("muere_boss", muere_boss)
	s.queue_free()
	if Progreso.current_map == 3:
		fin_game()
	else:
		Progreso.current_map += 1
	player.queue_free()
	current_map.queue_free()
	arrow_container.get_children().map(func(f): f.queue_free())
	load_map(Progreso.current_map)
	
func spawn_player() -> void:
	var player_instancia = player_scene.instantiate()
	add_child(player_instancia)
	player = player_instancia
	player.stats = Progreso.progreso_permanente.duplicate()
	player.find_child("Timer").wait_time = 1 / player.stats["p_attack_speed"]
	player.position_updated.connect(on_player_position_updated)
	player.player_dead.connect(player_dead)
	player_instancia.global_position = current_map.get_spawn_point()
	Progreso.player = player
func _physics_process(delta: float) -> void:
	if is_playing():
		$Camera3D.global_position.z = player.global_position.z -3
		$Camera3D.global_position.x = player.global_position.x

func on_player_position_updated(player_pos) -> void:
	pass#print(player_pos)

func player_dead() -> void:
	Progreso.current_map = 1
	partida_iniciada = false
	player.queue_free()
	current_map.queue_free()
	show_principal()
	
func pause_game() -> void:
	if get_tree().paused == false:
		get_tree().paused = true
	else:
		get_tree().paused = false 

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		pause_game()


func _on_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		iniciar_partida()

func _on_label_3_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().quit()

func _on_label_2_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		show_mejoras()

func is_playing() -> bool:
	return partida_iniciada

func show_principal() -> void:
	$HUD/gold.hide()
	fade.fade_in_out(0.5,1.5)
	await get_tree().create_timer(0.6).timeout
	menu_mejoras.hide()
	menu_principal.show()
	
	
func show_mejoras() -> void:
	$HUD/gold.show()
	menu_mejoras.show()
	menu_principal.hide()
	
func show_game() -> void:
	menu_mejoras.hide()
	menu_principal.hide()
	fade.fade_in_out(0.2, 1.5)
	load_map(Progreso.current_map)

	$HUD/gold.show()
	partida_iniciada = true
	
func fin_game() -> void:
	print("final de juego, Enhorabuena")
	get_tree().quit()
