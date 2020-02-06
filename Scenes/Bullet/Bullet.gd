extends Area2D

export var damage = 5.0
var speed = 500

func _process(delta: float) -> void:
	position.y -= speed * delta

func _on_Bomb_body_entered(body: Node) -> void:
	if body.is_in_group("blimp"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
