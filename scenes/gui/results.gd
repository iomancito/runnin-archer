class_name Results extends OverlayPanel

signal next_pressed
signal retry_pressed
signal shop_pressed
signal menu_pressed

@onready var title : Label = %Title
@onready var subtitle : Label = %Subtitle

#los botones no se pueden pulsar hasta un toque nuevo (al soltarlo): el dedo con el que se
#jugaba no debe elegir una opción sin querer ni cortar la música de victoria o derrota.
#Segundos tras aparecer en los que se ignoran los toques
const ESPERA_TOQUE : float = 0.6
var _esperando : bool = false
var _pulsado : bool = false
var _desde : int = 0
var _tween_aviso : Tween

func _ready() -> void:
	super()
	%NextButton.pressed.connect(func(): next_pressed.emit())
	%RetryButton.pressed.connect(func(): retry_pressed.emit())
	%ShopButton.pressed.connect(func(): shop_pressed.emit())
	%MenuButton.pressed.connect(func(): menu_pressed.emit())

func show_defeat(stats : Dictionary) -> void:
	_fill("DEFEATED", "Upgrade your archer and try again!", Color(1, 0.42, 0.36), stats)
	_buttons(false, true, true)

func show_cleared(map_index : int, stats : Dictionary) -> void:
	_fill("MAP %d CLEARED!" % map_index, "The boss has fallen. Onwards!", Color(1, 0.82, 0.3), stats)
	_buttons(true, false, false)

#desbloqueada: dificultad recién desbloqueada; arco: arco nuevo en la tienda ("" si ninguno)
func show_victory(stats : Dictionary, desbloqueada : String = "", arco : String = "") -> void:
	var lineas = []
	if desbloqueada != "":
		lineas.append("%s difficulty unlocked!" % Balance.DIFICULTADES[desbloqueada].nombre)
	if arco != "":
		lineas.append("New bow in the shop: %s" % Balance.ARCOS[arco].nombre)
	var texto = "You defeated every boss. Legendary archer!" if lineas.is_empty() else "\n".join(lineas)
	_fill("VICTORY!", texto, Color(1, 0.82, 0.3), stats)
	_buttons(false, false, true)

func _fill(t : String, sub : String, color : Color, stats : Dictionary) -> void:
	title.text = t
	title.add_theme_color_override("font_color", color)
	subtitle.text = sub
	%Distance.text = "%d%%" % stats.get("distance", 0)
	%Kills.text = str(stats.get("kills", 0))
	%Gold.text = "+%d" % stats.get("gold", 0)
	_espera_toque()
	show()

func _espera_toque() -> void:
	_esperando = true
	_pulsado = false
	_desde = Time.get_ticks_msec()
	_activa_botones(false)
	%Botones.modulate.a = 0.0
	var aviso : Label = %TapLabel
	aviso.show()
	aviso.modulate.a = 1.0
	if _tween_aviso:
		_tween_aviso.kill()
	_tween_aviso = create_tween().set_loops()
	_tween_aviso.tween_property(aviso, "modulate:a", 0.35, 0.7).set_trans(Tween.TRANS_SINE)
	_tween_aviso.tween_property(aviso, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)

func _input(event : InputEvent) -> void:
	if not _esperando or not visible:
		return
	var toque = event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT)
	if not toque:
		return
	get_viewport().set_input_as_handled()
	if event.pressed:
		_pulsado = Time.get_ticks_msec() - _desde >= ESPERA_TOQUE * 1000
	elif _pulsado:
		_muestra_botones()

func _muestra_botones() -> void:
	_esperando = false
	if _tween_aviso:
		_tween_aviso.kill()
	%TapLabel.hide()
	_activa_botones(true)
	create_tween().tween_property(%Botones, "modulate:a", 1.0, 0.2)

func _activa_botones(si : bool) -> void:
	for b in %Botones.get_children():
		b.disabled = not si

func _buttons(next : bool, retry : bool, shop : bool) -> void:
	%NextButton.visible = next
	%RetryButton.visible = retry
	%ShopButton.visible = shop
