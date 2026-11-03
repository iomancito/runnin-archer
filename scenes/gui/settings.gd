class_name SettingsScreen extends Control

## Ajustes: pestaña de audio (volumen de música y efectos) y de vídeo (calidad y FPS).
## Los valores viven en el autoload Ajustes; esta pantalla solo los muestra y cambia.
## Textos visibles en inglés.

signal back_pressed

const INFO_CALIDAD : Dictionary = {
	"auto": "Adjusts to your device while you play. Now: %s.",
	"low": "No shadows, lower resolution. For older phones.",
	"medium": "No shadows. Smoother and uses less battery.",
	"high": "Real-time shadows.",
	"ultra": "Shadows and full resolution. Needs a powerful phone.",
}
const INFO_FPS : Dictionary = {
	30: "Saves battery and keeps the phone cooler.",
	60: "Smoothest movement.",
}

var _botones_calidad : Dictionary = {}
var _botones_fps : Dictionary = {}

func _ready() -> void:
	%BackButton.pressed.connect(_volver)
	%AudioTab.pressed.connect(_pestana.bind(true))
	%VideoTab.pressed.connect(_pestana.bind(false))
	for barra in [%MusicaBarra, %EfectosBarra]:
		_estilo_barra(barra)
	%MusicaBarra.value_changed.connect(_on_musica)
	%EfectosBarra.value_changed.connect(_on_efectos)
	#AUTO en su fila, los niveles debajo
	var fila_auto = HBoxContainer.new()
	var fila_niveles = HBoxContainer.new()
	fila_niveles.add_theme_constant_override("separation", 8)
	%CalidadFila.add_child(fila_auto)
	%CalidadFila.add_child(fila_niveles)
	_botones_calidad["auto"] = _boton("AUTO", fila_auto, _on_calidad.bind("auto"))
	for n in Ajustes.ORDEN_NIVELES:
		_botones_calidad[n] = _boton(Ajustes.NIVELES[n].nombre.to_upper(), fila_niveles, _on_calidad.bind(n))
	for f in Ajustes.OPCIONES_FPS:
		_botones_fps[f] = _boton("%d FPS" % f, %FpsFila, _on_fps.bind(f))
	Ajustes.calidad_cambiada.connect(_refresca)
	visibility_changed.connect(func(): if visible: _pestana(true))
	_pestana(true)

func _boton(texto : String, fila : Container, al_pulsar : Callable) -> Button:
	var b = Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(0, 76)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	#letra algo menor: con los márgenes del tema caben 4 botones por fila
	b.add_theme_font_size_override("font_size", 21)
	b.pressed.connect(al_pulsar)
	fila.add_child(b)
	return b

func _pestana(audio : bool) -> void:
	%Audio.visible = audio
	%Video.visible = not audio
	%AudioTab.theme_type_variation = &"PrimaryButton" if audio else &""
	%VideoTab.theme_type_variation = &"" if audio else &"PrimaryButton"
	_refresca()

func _refresca() -> void:
	%MusicaBarra.set_value_no_signal(roundf(Ajustes.musica * 100))
	%EfectosBarra.set_value_no_signal(roundf(Ajustes.efectos * 100))
	_texto_volumen(%MusicaValor, Ajustes.musica)
	_texto_volumen(%EfectosValor, Ajustes.efectos)
	for c in _botones_calidad:
		_botones_calidad[c].theme_type_variation = &"PrimaryButton" if c == Ajustes.calidad else &""
	var info : String = INFO_CALIDAD[Ajustes.calidad]
	if Ajustes.calidad == "auto":
		info = info % Ajustes.NIVELES[Ajustes.nivel()].nombre
	%CalidadInfo.text = info
	for f in _botones_fps:
		_botones_fps[f].theme_type_variation = &"PrimaryButton" if f == Ajustes.fps else &""
	%FpsInfo.text = INFO_FPS[Ajustes.fps]

func _texto_volumen(etiqueta : Label, v : float) -> void:
	etiqueta.text = "MUTED" if v <= 0.0 else "%d%%" % roundi(v * 100)

func _on_musica(valor : float) -> void:
	Ajustes.musica = valor / 100.0
	Ajustes.aplica()
	_texto_volumen(%MusicaValor, Ajustes.musica)

func _on_efectos(valor : float) -> void:
	Ajustes.efectos = valor / 100.0
	Ajustes.aplica()
	#para oír el volumen elegido
	Sonidos.toca("click")
	_texto_volumen(%EfectosValor, Ajustes.efectos)

func _on_calidad(c : String) -> void:
	Ajustes.calidad = c
	Ajustes.aplica()
	_refresca()

func _on_fps(f : int) -> void:
	Ajustes.fps = f
	Ajustes.aplica()
	_refresca()

#se guarda al salir, no en cada movimiento de la barra
func _volver() -> void:
	Ajustes.guarda()
	back_pressed.emit()

#barra gruesa y tirador grande, fáciles de usar con el dedo
func _estilo_barra(barra : HSlider) -> void:
	var pista = StyleBoxFlat.new()
	pista.bg_color = Color(0.1, 0.07, 0.05, 0.9)
	pista.set_corner_radius_all(10)
	pista.content_margin_top = 10
	pista.content_margin_bottom = 10
	var lleno = pista.duplicate()
	lleno.bg_color = Color(1.0, 0.8, 0.22)
	barra.add_theme_stylebox_override("slider", pista)
	barra.add_theme_stylebox_override("grabber_area", lleno)
	barra.add_theme_stylebox_override("grabber_area_highlight", lleno)
	var tirador = _textura_tirador(52)
	barra.add_theme_icon_override("grabber", tirador)
	barra.add_theme_icon_override("grabber_highlight", tirador)

func _textura_tirador(lado : int) -> Texture2D:
	var g = Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.72, 0.78, 0.94, 1.0])
	g.colors = PackedColorArray([Color(1, 0.92, 0.6), Color(1, 0.85, 0.35), Color(0.45, 0.28, 0.06),
		Color(0.45, 0.28, 0.06), Color(0.45, 0.28, 0.06, 0)])
	var t = GradientTexture2D.new()
	t.gradient = g
	t.width = lado
	t.height = lado
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t
