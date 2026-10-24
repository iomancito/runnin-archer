class_name GameHUD extends Control

signal pause_pressed

@onready var hp_bar : ProgressBar = %HPBar
@onready var hp_text : Label = %HPText
@onready var map_label : Label = %MapLabel
@onready var distance_bar : ProgressBar = %DistanceBar
@onready var boss_box : Control = %BossBox
@onready var boss_name_label : Label = %BossName
@onready var boss_bar : ProgressBar = %BossBar
@onready var damage_flash : ColorRect = %DamageFlash

#distancia a la que aparece la barra de vida del boss
const BOSS_BAR_DISTANCE : float = 25.0

var player : Node3D
var boss : Enemy
var start_z : float = 0.0

func _ready() -> void:
	%PauseButton.pressed.connect(func(): pause_pressed.emit())
	damage_flash.modulate.a = 0.0

func start_run(map_index : int, p : Node3D, b : Enemy, boss_name : String) -> void:
	player = p
	boss = b
	start_z = player.global_position.z
	map_label.text = "MAP %d · %s" % [map_index, Balance.dif().nombre.to_upper()]
	distance_bar.value = 0
	boss_name_label.text = boss_name.to_upper()
	boss_box.hide()
	player.vida_changed.connect(_on_vida_changed)
	hp_bar.max_value = player.stats["p_vida"]
	hp_bar.value = player.vida
	hp_text.text = "%d / %d" % [player.vida, player.stats["p_vida"]]

func _process(_delta: float) -> void:
	if not visible or not is_instance_valid(player) or not is_instance_valid(boss):
		return
	var recorrido = boss.global_position.z - start_z
	if recorrido > 0:
		distance_bar.value = clampf((player.global_position.z - start_z) / recorrido, 0, 1) * 100
	if not boss_box.visible and boss.global_position.z - player.global_position.z < BOSS_BAR_DISTANCE:
		boss_box.show()
	if boss_box.visible:
		boss_bar.value = float(boss.vida) / max(1, boss.vida_max) * 100

func _on_vida_changed(vida : int, vida_max : int) -> void:
	hp_bar.max_value = vida_max
	hp_text.text = "%d / %d" % [max(vida, 0), vida_max]
	var anterior = hp_bar.value
	create_tween().tween_property(hp_bar, "value", max(vida, 0), 0.25)
	if vida < anterior:
		#destello rojo al recibir daño
		var tw = create_tween()
		tw.tween_property(damage_flash, "modulate:a", 1.0, 0.05)
		tw.tween_property(damage_flash, "modulate:a", 0.0, 0.35)
