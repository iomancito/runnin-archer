class_name MainMenu extends Control

signal play_pressed
signal shop_pressed
signal exit_pressed

@onready var progress_label : Label = %ProgressLabel
@onready var play_button : Button = %PlayButton

func _ready() -> void:
	play_button.pressed.connect(func(): play_pressed.emit())
	%ShopButton.pressed.connect(func(): shop_pressed.emit())
	%ExitButton.pressed.connect(func(): exit_pressed.emit())
	#en web/iOS no se puede cerrar la app
	%ExitButton.visible = OS.get_name() not in ["Web", "iOS"]
	visibility_changed.connect(_refresh)
	_refresh()
	_pulse_play()

func _refresh() -> void:
	if visible:
		progress_label.text = "Furthest map: %d / 3" % Progreso.max_map

#latido suave del botón PLAY
func _pulse_play() -> void:
	await play_button.resized
	play_button.pivot_offset = play_button.size * 0.5
	var tw = create_tween().set_loops()
	tw.tween_property(play_button, "scale", Vector2(1.05, 1.05), 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(play_button, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)
