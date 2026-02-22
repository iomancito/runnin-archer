extends CharacterBody3D


func _on_area_daño_body_entered(body: Node3D) -> void:
	if body is Player:
		body.recibe_daño(20)
		
func _physics_process(delta: float) -> void:
	move_and_slide()
