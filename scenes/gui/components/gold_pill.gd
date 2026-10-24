class_name GoldPill extends PanelContainer

@onready var label : Label = $HBox/Amount

func _ready() -> void:
	Progreso.gold_changed.connect(_on_gold_changed)
	label.text = str(Progreso.p_gold)

func _on_gold_changed(gold : int) -> void:
	var subida = gold > int(label.text)
	label.text = str(gold)
	if subida and is_visible_in_tree():
		#pequeño rebote al ganar oro
		pivot_offset = size * 0.5
		var tw = create_tween()
		tw.tween_property(self, "scale", Vector2(1.12, 1.12), 0.06)
		tw.tween_property(self, "scale", Vector2.ONE, 0.12)
