extends Area2D

var timestamp_class = preload("res://Scripts/Timestamp.gd")

export var damage = 9
var speed = 750
var fire = false
var movement = Vector2(0, -1)
var current_time = timestamp_class.timestamp.new()
var fired_time = timestamp_class.timestamp.new()

func _process(delta: float) -> void:
	if fire:
		position.y += speed * movement.y * delta
		position.x += speed * movement.x * delta
		current_time.reset_time()
		var ticks_fire = current_time.subtract_ticks(fired_time)
		if ticks_fire >= 1000:
			fire = false
			queue_free()

func set_movement_vector(move_direction):
	movement = move_direction

func _ready():
	visible = false
	$Particles2D.emitting = false

func fire():
	fired_time.reset_time()
	print("FlakScatter, fire(), position=%s" % [position])
	fire = true
	visible = true
	$Particles2D.emitting = true

#func _init(_speed):
#	speed = _speed


func _on_FlakScatter_body_entered(body):
	if body.is_in_group("blimp"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
