class_name AchievementsScreen extends Control

## Pantalla de logros: pestaña GENERAL y pestaña CHALLENGES (retos por mapa, agrupados por
## dificultad). Los conseguidos se ven normales; los pendientes, oscurecidos.

signal back_pressed

#oscurecido de los logros pendientes
const COLOR_PENDIENTE : Color = Color(0.45, 0.45, 0.45)

#id -> {panel, medalla, progreso}
var filas : Dictionary = {}

func _ready() -> void:
	%BackButton.pressed.connect(func(): back_pressed.emit())
	%TabGeneral.pressed.connect(_muestra_pestaña.bind(false))
	%TabRetos.pressed.connect(_muestra_pestaña.bind(true))
	var grupo = ""
	for l in Logros.lista:
		var es_general = l.grupo == Logros.GENERAL
		var destino : VBoxContainer = %General if es_general else %Retos
		if not es_general and l.grupo != grupo:
			grupo = l.grupo
			var cabecera = Label.new()
			cabecera.text = Balance.DIFICULTADES[grupo].nombre.to_upper()
			cabecera.theme_type_variation = &"HeaderLabel"
			cabecera.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			destino.add_child(cabecera)
		destino.add_child(_crea_fila(l))
	Logros.desbloqueado.connect(func(_id): if visible: _refresh())
	visibility_changed.connect(func(): if visible: _refresh())
	_muestra_pestaña(false)

func _crea_fila(l : Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.theme_type_variation = &"CardPanel"
	#que el arrastre llegue al ScrollContainer
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)
	panel.add_child(fila)
	var medalla = MedalIcon.new()
	medalla.custom_minimum_size = Vector2(72, 72)
	medalla.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(medalla)
	var textos = VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_theme_constant_override("separation", 2)
	fila.add_child(textos)
	var nombre = Label.new()
	nombre.text = l.nombre
	nombre.theme_type_variation = &"HeaderLabel"
	nombre.add_theme_font_size_override("font_size", 30)
	textos.add_child(nombre)
	var texto = Label.new()
	texto.text = l.texto
	texto.theme_type_variation = &"SmallLabel"
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	textos.add_child(texto)
	var progreso = Label.new()
	progreso.theme_type_variation = &"SmallLabel"
	progreso.add_theme_color_override("font_color", Color(1.0, 0.84, 0.3))
	textos.add_child(progreso)
	for n in [fila, medalla, textos, nombre, texto, progreso]:
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	filas[l.id] = {"panel": panel, "medalla": medalla, "progreso": progreso}
	return panel

func _refresh() -> void:
	%Contador.text = "%d / %d" % [Logros.total_conseguidos(), Logros.lista.size()]
	for id in filas:
		var f = filas[id]
		var hecho = Logros.tiene(id)
		f.panel.modulate = Color.WHITE if hecho else COLOR_PENDIENTE
		f.medalla.encendida = hecho
		var p = Logros.progreso_de(id)
		f.progreso.visible = not hecho and not p.is_empty()
		if f.progreso.visible:
			f.progreso.text = "%s / %s" % [Logros.num_txt(p[0]), Logros.num_txt(p[1])]

func _muestra_pestaña(retos : bool) -> void:
	%General.visible = not retos
	%Retos.visible = retos
	%TabGeneral.theme_type_variation = &"" if retos else &"PrimaryButton"
	%TabRetos.theme_type_variation = &"PrimaryButton" if retos else &""
	%Scroll.scroll_vertical = 0
