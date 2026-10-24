class_name Shop extends Control

signal back_pressed

const CARD_SCENE : PackedScene = preload("res://scenes/gui/shop_card.tscn")
#segundos para confirmar el reset
const RESET_CONFIRM_TIME : float = 3.0

@onready var grid : GridContainer = %Grid
@onready var reset_button : Button = %ResetButton

var pasivas_array : Array[Pasiva] = []
var cards : Array[ShopCard] = []
var reset_armed : bool = false

func _ready() -> void:
	#nombre (clave de guardado), título, formato del valor, stat, incremento por nivel
	_add("arrow_distance", "Range", "%d m", "f_max_distancia", 4)
	_add("arrow_speed", "Arrow Speed", "%d", "f_velocidad", 30)
	_add("side_walk_speed", "Dodge Speed", "%d", "p_side_speed", 5)
	_add("walk_speed", "Run Speed", "%d", "p_speed", 20)
	_add("attack_speed", "Fire Rate", "%.1f/s", "p_attack_speed", 0.2)
	_add("damage", "Damage", "%d", "f_daño", 2)
	_add("arrow_number", "Arrows", "%d", "f_cantidad", 1)
	_add("vida", "Max HP", "%d", "p_vida", 10)
	#niveles guardados
	for p in pasivas_array:
		p.nivel = clampi(Progreso.niveles.get(p.nombre, 0), 0, p.nivel_max)
	recalcula_stats()
	for p in pasivas_array:
		var card : ShopCard = CARD_SCENE.instantiate()
		grid.add_child(card)
		card.buy_pressed.connect(_on_buy_pressed.bind(cards.size()))
		cards.append(card)
	%BackButton.pressed.connect(func(): back_pressed.emit())
	reset_button.pressed.connect(_on_reset_pressed)
	Progreso.gold_changed.connect(func(_g): actualiza_txt())
	visibility_changed.connect(_on_visibility_changed)
	actualiza_txt()

func _add(nombre : String, titulo : String, formato : String, stat : String, incremento : float) -> void:
	var p = Pasiva.new(nombre, [1,2,3,4,5], 0, 5, stat, incremento)
	p.titulo = titulo
	p.formato = formato
	pasivas_array.append(p)

#stats permanentes = base + incremento * nivel de cada pasiva
func recalcula_stats() -> void:
	var skin = Progreso.progreso_permanente["a_skin"]
	Progreso.progreso_permanente = Progreso.BASE_STATS.duplicate()
	Progreso.progreso_permanente["a_skin"] = skin
	for p in pasivas_array:
		var base = Progreso.progreso_permanente[p.stat]
		#mantiene el tipo (int/float) del valor base
		Progreso.progreso_permanente[p.stat] = type_convert(base + p.incremento * p.nivel, typeof(base))

func actualiza_txt() -> void:
	for i in cards.size():
		var p = pasivas_array[i]
		var valor = Progreso.progreso_permanente[p.stat]
		cards[i].refresh(p.titulo, p.nivel, p.nivel_max, p.formato % valor, p.formato % (valor + p.incremento),
				p.get_coste_next(), Progreso.p_gold >= p.get_coste_next())
	var gastado = 0
	for p in pasivas_array:
		gastado += p.get_money()
	reset_button.disabled = gastado == 0
	if not reset_armed:
		reset_button.text = "RESET UPGRADES"

func _on_buy_pressed(i : int) -> void:
	if subir_lvl_pasiva(pasivas_array[i]):
		cards[i].pulse()

func subir_lvl_pasiva(ref) -> bool:
	var ret = false
	if ref.puede_subir() and Progreso.p_gold >= ref.get_coste_next():
		ret = ref.subir_lvl()
		Progreso.niveles[ref.nombre] = ref.nivel
		recalcula_stats()
		Progreso.p_gold -= ref.get_coste()
		Progreso.save_game()
	return ret

#primer toque arma el reset, el segundo lo confirma
func _on_reset_pressed() -> void:
	if not reset_armed:
		var total = 0
		for p in pasivas_array:
			total += p.get_money()
		reset_armed = true
		reset_button.text = "TAP AGAIN: REFUND %d" % total
		await get_tree().create_timer(RESET_CONFIRM_TIME).timeout
		if reset_armed:
			reset_armed = false
			actualiza_txt()
		return
	reset_armed = false
	reset_pasivas()

#devuelve todo el oro gastado y deja las pasivas a nivel 0
func reset_pasivas() -> void:
	var reembolso = 0
	for p in pasivas_array:
		reembolso += p.get_money()
		p.nivel = 0
	Progreso.niveles.clear()
	recalcula_stats()
	Progreso.p_gold += reembolso
	Progreso.save_game()
	actualiza_txt()

func _on_visibility_changed() -> void:
	reset_armed = false
	if visible:
		actualiza_txt()

class Pasiva:
	
	var nombre :String
	var titulo : String
	var formato : String = "%d"
	var costes: Array
	var nivel : int
	var nivel_max :int
	var stat : String #clave en Progreso.progreso_permanente
	var incremento : float #cuanto suma cada nivel
	
	func _init(nom : String = "", cost : Array[int] = [],niv : int = 0, nivmax : int = 0, st : String = "", inc : float = 0) -> void:
		nombre = nom
		costes = cost.duplicate()
		nivel = niv
		nivel_max = nivmax
		stat = st
		incremento = inc
		
	func subir_lvl() -> bool:
		if nivel < nivel_max:
			nivel +=1
			return true
		return false
			
	func get_coste_next() -> int:
		if nivel < nivel_max:
			return costes[nivel]
		return 0
		
	func get_coste() -> int:
		return costes[nivel-1]
		
	func puede_subir() -> bool:
		return nivel < nivel_max
		
	func get_money() -> int:
		if nivel == 0:
			return 0
		var total = 0
		for i in range(0,nivel):
			total += costes[i]
		return total
