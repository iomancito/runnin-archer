class_name Main extends Node3D

signal mapa_cargado

@export var player_scene : PackedScene

@onready var map_container = $MapContainer
@onready var enemies_container = $EnemiesContainer
@onready var arrow_container = $ArrowContainer
@onready var game_hud : GameHUD = %GameHUD
@onready var menu_principal : MainMenu = %MainMenu
@onready var menu_mejoras : Shop = %Shop
@onready var pause_menu : PauseMenu = %PauseMenu
@onready var results : Results = %Results
@onready var fade = %fade

var player
var partida_iniciada : bool = false

var current_map: Node3D
# En vez de índices, almacena referencias directas:
var spawned_enemies: Array[Node3D] = []

func _ready() -> void:
	#el botón atrás de android lo gestiona _notification
	get_tree().set_quit_on_go_back(false)
	menu_principal.play_pressed.connect(iniciar_partida)
	menu_principal.shop_pressed.connect(show_mejoras)
	menu_principal.exit_pressed.connect(salir)
	menu_mejoras.back_pressed.connect(show_principal)
	game_hud.pause_pressed.connect(pause_game)
	pause_menu.resume_pressed.connect(pause_game)
	pause_menu.menu_pressed.connect(abandonar_partida)
	results.next_pressed.connect(siguiente_mapa)
	results.retry_pressed.connect(func(): limpiar_mundo(); iniciar_partida())
	results.shop_pressed.connect(func(): limpiar_mundo(); show_mejoras())
	results.menu_pressed.connect(func(): limpiar_mundo(); show_principal())
	fade.fade_in_out(0.1, 2)

func iniciar_partida() -> void:
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
	Progreso.reset_run()
	game_hud.start_run(map_index, player, current_map.get_boss(), current_map.boss_name)

func muere_boss(s : Node3D) -> void :
	s.disconnect("muere_boss", muere_boss)
	s.queue_free()
	partida_iniciada = false
	var stats = run_stats(100)
	game_hud.hide()
	get_tree().paused = true
	if Progreso.current_map == 3:
		Progreso.current_map = 1
		Progreso.save_game()
		results.show_victory(stats)
		return
	Progreso.current_map += 1
	Progreso.max_map = max(Progreso.max_map, Progreso.current_map)
	Progreso.save_game()
	results.show_cleared(Progreso.current_map - 1, stats)

func siguiente_mapa() -> void:
	limpiar_mundo()
	show_game()

func spawn_player() -> void:
	var player_instancia = player_scene.instantiate()
	player = player_instancia
	#los stats se asignan antes de add_child para que _ready() del player los use
	player.stats = Progreso.progreso_permanente.duplicate()
	#Main procesa siempre (menús en pausa), el player debe pausarse
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player_instancia)
	player.position_updated.connect(on_player_position_updated)
	player.player_dead.connect(player_dead)
	player_instancia.global_position = current_map.get_spawn_point()
	Progreso.player = player

func _physics_process(delta: float) -> void:
	if is_playing() and is_instance_valid(player):
		$Camera3D.global_position.z = player.global_position.z -3
		$Camera3D.global_position.x = player.global_position.x

func on_player_position_updated(player_pos) -> void:
	pass#print(player_pos)

func player_dead() -> void:
	Progreso.current_map = 1
	partida_iniciada = false
	Progreso.save_game()
	var stats = run_stats(game_hud.distance_bar.value)
	game_hud.hide()
	#congela la escena detrás de la pantalla de resultados
	get_tree().paused = true
	results.show_defeat(stats)

func run_stats(distancia : float) -> Dictionary:
	return {"distance": int(distancia), "kills": Progreso.run_kills, "gold": Progreso.run_gold}

#libera el mapa, el player y las flechas de la partida actual
func limpiar_mundo() -> void:
	get_tree().paused = false
	results.hide()
	pause_menu.hide()
	game_hud.hide()
	if is_instance_valid(player):
		player.queue_free()
	if is_instance_valid(current_map):
		current_map.queue_free()
	current_map = null
	arrow_container.get_children().map(func(f): f.queue_free())

#salir de la partida desde el menú de pausa
func abandonar_partida() -> void:
	partida_iniciada = false
	Progreso.current_map = 1
	Progreso.save_game()
	limpiar_mundo()
	show_principal()

func pause_game() -> void:
	if not is_playing():
		return
	get_tree().paused = not get_tree().paused
	pause_menu.visible = get_tree().paused

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		pause_game()
	elif event.is_action_pressed("ui_cancel"):
		_on_back()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back()
	#pausa automática si la app pasa a segundo plano
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if is_playing() and not get_tree().paused:
			pause_game()

#botón atrás de android / escape
func _on_back() -> void:
	if menu_mejoras.visible:
		show_principal()
	elif is_playing():
		pause_game()
	elif menu_principal.visible:
		salir()

func salir() -> void:
	Progreso.save_game()
	get_tree().quit()

func is_playing() -> bool:
	return partida_iniciada

func show_principal() -> void:
	fade.fade_in_out(0.5,1.5)
	await get_tree().create_timer(0.6).timeout
	menu_mejoras.hide()
	menu_principal.show()

func show_mejoras() -> void:
	menu_mejoras.show()
	menu_principal.hide()

func show_game() -> void:
	menu_mejoras.hide()
	menu_principal.hide()
	fade.fade_in_out(0.2, 1.5)
	load_map(Progreso.current_map)
	game_hud.show()
	partida_iniciada = true
