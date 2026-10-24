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
	#mejoras, incrementos y precios definidos en Balance
	for d in Balance.tienda():
		_add(d[0], d[1], d[2], d[3], d[4], d[5])
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
	Progreso.progress_reset.connect(_on_progress_reset)
	visibility_changed.connect(_on_visibility_changed)
	actualiza_txt()

func _add(nombre : String, titulo : String, formato : String, stat : String, incremento : float, costes : Array) -> void:
	var p = Pasiva.new(nombre, costes, 0, costes.size(), stat, incremento)
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

#reset total desde el menú principal: niveles a 0 sin reembolso
func _on_progress_reset() -> void:
	for p in pasivas_array:
		p.nivel = 0
	recalcula_stats()
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
	
	func _init(nom : String = "", cost : Array = [],niv : int = 0, nivmax : int = 0, st : String = "", inc : float = 0) -> void:
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
