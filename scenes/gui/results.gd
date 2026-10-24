class_name Results extends OverlayPanel

signal next_pressed
signal retry_pressed
signal shop_pressed
signal menu_pressed

@onready var title : Label = %Title
@onready var subtitle : Label = %Subtitle

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

func show_victory(stats : Dictionary) -> void:
	_fill("VICTORY!", "You defeated every boss. Legendary archer!", Color(1, 0.82, 0.3), stats)
	_buttons(false, false, true)

func _fill(t : String, sub : String, color : Color, stats : Dictionary) -> void:
	title.text = t
	title.add_theme_color_override("font_color", color)
	subtitle.text = sub
	%Distance.text = "%d%%" % stats.get("distance", 0)
	%Kills.text = str(stats.get("kills", 0))
	%Gold.text = "+%d" % stats.get("gold", 0)
	show()

func _buttons(next : bool, retry : bool, shop : bool) -> void:
	%NextButton.visible = next
	%RetryButton.visible = retry
	%ShopButton.visible = shop
