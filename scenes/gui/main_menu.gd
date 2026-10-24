class_name MainMenu extends Control

signal play_pressed
signal shop_pressed
signal achievements_pressed
signal exit_pressed

@onready var progress_label : Label = %ProgressLabel
@onready var play_button : Button = %PlayButton
@onready var reset_button : Button = %ResetButton

#segundos para confirmar el borrado
const RESET_CONFIRM_TIME : float = 3.0
const RESET_TEXT : String = "RESET PROGRESS"
var reset_armed : bool = false

func _ready() -> void:
	play_button.pressed.connect(func(): play_pressed.emit())
	%ShopButton.pressed.connect(func(): shop_pressed.emit())
	%AchievementsButton.pressed.connect(func(): achievements_pressed.emit())
	%ExitButton.pressed.connect(func(): exit_pressed.emit())
	#en web/iOS no se puede cerrar la app
	%ExitButton.visible = OS.get_name() not in ["Web", "iOS"]
	reset_button.pressed.connect(_on_reset_pressed)
	for d in Balance.ORDEN_DIFICULTADES:
		var b = Button.new()
		b.text = Balance.DIFICULTADES[d].nombre.to_upper()
		b.custom_minimum_size = Vector2(110, 72)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(_on_dificultad_pressed.bind(d))
		%DiffRow.add_child(b)
	visibility_changed.connect(_refresh)
	_refresh()
	_pulse_play()

func _refresh() -> void:
	reset_armed = false
	reset_button.text = RESET_TEXT
	if visible:
		progress_label.text = "Furthest map (%s): %d / 3" % [Balance.dif().nombre, Progreso.max_map]
		var siguiente = Progreso.siguiente_dificultad(Progreso.dificultad)
		if siguiente != "" and not Progreso.esta_desbloqueada(siguiente):
			progress_label.text += "\nBeat map 3 on %s to unlock %s" % [Balance.dif().nombre, Balance.DIFICULTADES[siguiente].nombre]
		_marca_dificultad()
		if Progreso.aviso != "":
			progress_label.text += "\n" + Progreso.aviso
			Progreso.aviso = ""

func _on_dificultad_pressed(d : String) -> void:
	if not Progreso.esta_desbloqueada(d):
		return
	Progreso.dificultad = d
	Progreso.save_game()
	_refresh()

#resalta la dificultad elegida (verde, o rojo en Hell)
func _marca_dificultad() -> void:
	for i in Balance.ORDEN_DIFICULTADES.size():
		var d = Balance.ORDEN_DIFICULTADES[i]
		var b : Button = %DiffRow.get_child(i)
		b.disabled = not Progreso.esta_desbloqueada(d)
		if d != Progreso.dificultad:
			b.theme_type_variation = &""
		else:
			b.theme_type_variation = &"DangerButton" if d == "hell" else &"PrimaryButton"

#primer toque arma el borrado, el segundo lo confirma
func _on_reset_pressed() -> void:
	if not reset_armed:
		reset_armed = true
		reset_button.text = "TAP AGAIN TO ERASE ALL"
		await get_tree().create_timer(RESET_CONFIRM_TIME).timeout
		if reset_armed:
			reset_armed = false
			reset_button.text = RESET_TEXT
		return
	Progreso.reset_all()
	_refresh()
	progress_label.text += "\nProgress erased"

#latido suave del botón PLAY
func _pulse_play() -> void:
	await play_button.resized
	play_button.pivot_offset = play_button.size * 0.5
	var tw = create_tween().set_loops()
	tw.tween_property(play_button, "scale", Vector2(1.05, 1.05), 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(play_button, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)
