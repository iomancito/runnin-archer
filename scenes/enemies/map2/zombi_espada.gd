extends Enemy

var v = 0

func _ready() -> void:
	if randi_range(0,1) == 1:
		$AnimationPlayer.play("crawl")
		v = -2
	else:
		$AnimationPlayer.play("agonize")

func _physics_process(delta: float) -> void:
	velocity.z = v
	move_and_slide()

func update_hp() -> void:
	$Label3D.text = str(vida)
