extends Area2D

var group_class = preload("res://Scripts/Group.gd")
export var damage = 30.0
var gravity_ = 100

func _process(delta: float) -> void:
	position.y += gravity_ * delta

func _on_Bomb_body_entered(body: Node) -> void:
	print("Bomb, _on_Bomb_body_entered(), body=%s" % [body.name])
	if body.is_in_group("building"):
		body.take_damage(damage)
		queue_free()
	if body.is_in_group("shield"):
		body.take_hit()
