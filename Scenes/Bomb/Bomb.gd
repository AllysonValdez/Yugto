extends Area2D

var group_class = preload("res://Scripts/Group.gd")
var timestamp_class = preload("res://Scripts/Timestamp.gd")

signal shieldhit(full_damage)

export var damage = 30.0
var gravity_ = 100
var shield_absorbed_time = timestamp_class.timestamp.new()
var current_time = timestamp_class.timestamp.new()

func _process(delta: float) -> void:
	position.y += gravity_ * delta

func _ready():
	current_time.reset_time()
	shield_absorbed_time.reset_time()

func shield_take_hit():
	#Deplete the shield if it is close to the end of life
	emit_signal("shieldhit", damage)

func _on_Bomb_body_entered(body: Node) -> void:
	print("Bomb, _on_Bomb_body_entered(), body=%s" % [body.name])
	current_time.reset_time()
	var ticks_shield_absorbed = current_time.subtract_ticks(shield_absorbed_time)
	if ticks_shield_absorbed <= 800:
		pass
	if body.is_in_group("building"):
		body.take_damage(damage)
		queue_free()
	if body.is_in_group("shield"):
		shield_absorbed_time.reset_time()
		print("Bomb, _on_Bomb_body_entered(), shield took hit") #if body is an energy shield
		shield_take_hit()
		queue_free() # disintegrate effect ??
