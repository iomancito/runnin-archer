class_name ShopCard extends PanelContainer

signal buy_pressed

@onready var name_label : Label = %Name
@onready var value_label : Label = %Value
@onready var pips : HBoxContainer = %Pips
@onready var buy_button : Button = %BuyButton
@onready var cost_box : Control = %CostBox
@onready var cost_label : Label = %Cost

func _ready() -> void:
	buy_button.pressed.connect(func(): buy_pressed.emit())

func refresh(titulo : String, nivel : int, nivel_max : int, valor : String, valor_next : String, coste : int, puede_pagar : bool) -> void:
	name_label.text = titulo
	#un pip por nivel, se recrean si cambia el máximo
	if pips.get_child_count() != nivel_max:
		for c in pips.get_children():
			c.queue_free()
		for i in nivel_max:
			var pip = Panel.new()
			pip.custom_minimum_size = Vector2(0, 14)
			pip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pips.add_child(pip)
	for i in nivel_max:
		pips.get_child(i).theme_type_variation = &"PipOn" if i < nivel else &"PipOff"
	if nivel >= nivel_max:
		value_label.text = valor
		buy_button.text = "MAX"
		buy_button.disabled = true
		cost_box.hide()
	else:
		value_label.text = "%s  >  %s" % [valor, valor_next]
		buy_button.text = ""
		buy_button.disabled = not puede_pagar
		cost_box.show()
		cost_label.text = str(coste)
		cost_label.modulate = Color.WHITE if puede_pagar else Color(1, 0.55, 0.5)

func pulse() -> void:
	pivot_offset = size * 0.5
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.06, 1.06), 0.07)
	tw.tween_property(self, "scale", Vector2.ONE, 0.15)
