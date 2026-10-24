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
@onready var splash : TextureRect = %Splash

#segundos mínimos que se ve la pantalla de inicio aunque la carga acabe antes
const SPLASH_MIN : float = 3.0
#metros que la cámara va por detrás del player (negativo: por delante, mirando hacia abajo);
#en x queda fija en el centro del camino: su FOV horizontal (main.tscn) abarca las dos paredes
const CAMARA_DETRAS : float = -1.5

var player
var partida_iniciada : bool = false

const RUTAS_MAPAS : Array[String] = ["res://scenes/mapas/mapa1.tscn", "res://scenes/mapas/mapa2.tscn", "res://scenes/mapas/mapa3.tscn"]
#escenas de mapa ya cargadas (guardar la referencia evita que se descarguen)
var escenas_mapas : Dictionary = {}

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
	menu_mejoras.arco_equipado.connect(_precalentar_arco)
	game_hud.pause_pressed.connect(pause_game)
	pause_menu.resume_pressed.connect(pause_game)
	pause_menu.menu_pressed.connect(abandonar_partida)
	results.next_pressed.connect(siguiente_mapa)
	results.retry_pressed.connect(func(): limpiar_mundo(); iniciar_partida())
	results.shop_pressed.connect(func(): limpiar_mundo(); show_mejoras())
	results.menu_pressed.connect(func(): limpiar_mundo(); show_principal())
	_carga_inicial()

#pantalla de carga al arrancar: carga los mapas en segundo plano y compila sus shaders
#mostrando una vez cada modelo, para que la partida no se congele al empezar
func _carga_inicial() -> void:
	var inicio = Time.get_ticks_msec()
	splash.show()
	fade.hide()
	for ruta in RUTAS_MAPAS:
		ResourceLoader.load_threaded_request(ruta)
	var pendientes = RUTAS_MAPAS.duplicate()
	while not pendientes.is_empty():
		var progreso = 0.0
		for ruta in RUTAS_MAPAS:
			var p = []
			var estado = ResourceLoader.load_threaded_get_status(ruta, p)
			if estado == ResourceLoader.THREAD_LOAD_LOADED or estado == ResourceLoader.THREAD_LOAD_FAILED:
				pendientes.erase(ruta)
				progreso += 1.0
			elif not p.is_empty():
				progreso += p[0]
		_progreso_carga(progreso / RUTAS_MAPAS.size() * 70)
		await get_tree().process_frame
	for i in RUTAS_MAPAS.size():
		escenas_mapas[i + 1] = ResourceLoader.load_threaded_get(RUTAS_MAPAS[i])
	var camara_inicial = $Camera3D.global_position
	for n in escenas_mapas:
		_progreso_carga(70 + n * 10)
		await get_tree().process_frame
		var mapa = escenas_mapas[n].instantiate()
		map_container.add_child(mapa)
		mapa.precalentar()
		$Camera3D.global_position = Vector3(0, camara_inicial.y, mapa.get_spawn_point().z - CAMARA_DETRAS)
		#unos frames dibujando el mapa (tapado por la pantalla negra)
		for i in 3:
			await get_tree().process_frame
		mapa.queue_free()
	$Camera3D.global_position = camara_inicial
	_progreso_carga(100)
	var restante = SPLASH_MIN - (Time.get_ticks_msec() - inicio) / 1000.0
	if restante > 0:
		await get_tree().create_timer(restante).timeout
	#se oscurece la imagen y el menú principal entra con un fundido
	await fade.fade_in(0.6)
	splash.hide()
	await get_tree().create_timer(0.2).timeout
	fade.fade_out(0.8)

#efectos del arco recién equipado delante de la cámara, tapados por la tienda, unos frames
func _precalentar_arco(id : String) -> void:
	var nodo = Node3D.new()
	add_child(nodo)
	var camara = $Camera3D.global_position
	ArcoEfectos.precalentar(id, nodo, Vector3(camara.x, 0, camara.z + 8))
	for i in 3:
		await get_tree().process_frame
	nodo.queue_free()

func _progreso_carga(porcentaje : float) -> void:
	%Barra.value = porcentaje
	%Texto.text = "Loading %d%%" % int(porcentaje)

func iniciar_partida() -> void:
	show_game()

func load_map(map_index: int):
	# Eliminar mapa anterior
	if current_map != null:
		current_map.queue_free()

	# Cargar nuevo mapa (ej: map1.tscn, map2.tscn)
	var map_scene = escenas_mapas.get(map_index)
	if map_scene == null:
		map_scene = load("res://scenes/mapas/mapa{index}.tscn".format({"index": map_index}))
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
		var primera_vez = not Progreso.dificultad in Progreso.completadas
		var nueva = Progreso.completa_dificultad()
		Progreso.save_game()
		#el arco de esta dificultad pasa a la tienda la primera vez que se completa
		var arco_nuevo = ""
		if primera_vez:
			for id in Balance.ORDEN_ARCOS:
				if Balance.ARCOS[id].dificultad == Progreso.dificultad:
					arco_nuevo = id
		results.show_victory(stats, nueva, arco_nuevo)
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
	player.stats = Progreso.stats_partida()
	#Main procesa siempre (menús en pausa), el player debe pausarse
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player_instancia)
	player.position_updated.connect(on_player_position_updated)
	player.player_dead.connect(player_dead)
	player_instancia.global_position = current_map.get_spawn_point()
	Progreso.player = player

func _physics_process(delta: float) -> void:
	if is_playing() and is_instance_valid(player):
		$Camera3D.global_position.z = player.global_position.z - CAMARA_DETRAS

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
	#el mapa se monta con la pantalla en negro: el parón de construirlo no se ve
	await fade.fade_in(0.25)
	menu_mejoras.hide()
	menu_principal.hide()
	load_map(Progreso.current_map)
	game_hud.show()
	partida_iniciada = true
	await get_tree().process_frame
	await get_tree().process_frame
	fade.fade_out(0.6)
