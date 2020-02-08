extends Area2D

var group_class = preload("res://Scripts/Group.gd")
var timestamp_class = preload("res://Scripts/Timestamp.gd")

signal shieldhit(full_damage)

export var base_damage = 12.0 # 18.0
var gravity_ = 100
var shield_absorbed_time = timestamp_class.timestamp.new()
var current_time = timestamp_class.timestamp.new()

func _process(delta: float) -> void:
	position.y += gravity_ * delta

func _ready():
	current_time.reset_time()
	shield_absorbed_time.reset_time()

func shield_take_hit():
	#TO DO -- Deplete the shield if it is close to the end of life
	emit_signal("shieldhit", determine_bomb_damage()) # base_damage

func determine_bomb_damage():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var damage = base_damage
	var damage_tweak_slot = rng.randi_range(0, 3)
	var damage_reduce = 0.0
	match damage_tweak_slot:
		0: damage_reduce = 0.0
		1: damage_reduce = 0.075
		2: damage_reduce = 0.15
		3: damage_reduce = 0.34
	damage -= int(damage_reduce * base_damage)
	return damage

func _on_Bomb_body_entered(body: Node) -> void:
	print("Bomb, _on_Bomb_body_entered(), body=%s" % [body.name])
	current_time.reset_time()
	var ticks_shield_absorbed = current_time.subtract_ticks(shield_absorbed_time)
	if ticks_shield_absorbed <= 500: # Improve logic for 2 to 3 concurrent bombs at similar heights, TO DO
		pass
	if body.is_in_group("building"):
		body.take_damage(determine_bomb_damage())
		queue_free()
	if body.is_in_group("shield"):
		shield_absorbed_time.reset_time()
		print("Bomb, _on_Bomb_body_entered(), shield took hit") #if body is an energy shield
		shield_take_hit()
		queue_free() # disintegrate effect ??
