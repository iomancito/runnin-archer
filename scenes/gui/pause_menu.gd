class_name PauseMenu extends OverlayPanel

signal resume_pressed
signal menu_pressed

func _ready() -> void:
	super()
	%ResumeButton.pressed.connect(func(): resume_pressed.emit())
	%MenuButton.pressed.connect(func(): menu_pressed.emit())
