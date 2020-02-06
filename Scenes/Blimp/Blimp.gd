extends KinematicBody2D

var timestamp_class = preload("res://Scripts/Timestamp.gd")
var group_class = preload("res://Scripts/Group.gd")

onready var health_bar = $"HealthBar/HealthBar"
const BLIMP_SPEED = 300
var blimp_state = 0
var bomb_dropped_time = timestamp_class.timestamp.new()
var blimp_moveswitch_time = timestamp_class.timestamp.new()
var blimp_destroyed_time = timestamp_class.timestamp.new()

var speed = BLIMP_SPEED
var reached_end = false
var current_time = timestamp_class.timestamp.new()
var screen_size
signal bomb

func destroy_blimp():
	blimp_state = 2
	blimp_destroyed_time.reset_time()
	visible = false

func reset_blimp_state():
	blimp_state = 0
	visible = true
	position.x = 30
	speed = BLIMP_SPEED

func take_damage(damage):
	print("building")
	health_bar.value -= damage
	if health_bar.value <= 1.0:
		#The blimp has no more health and is destroyed
		#Show explosion animation....
		destroy_blimp()

func _ready():
	screen_size = get_viewport().size
	blimp_state = 0
	blimp_moveswitch_time.reset_time()
	position = Vector2(80.0, 105.0)
	align_blimp(speed)

func align_blimp(speed):
	if speed < 0:
		$Sprite.flip_h = false
	else:
		$Sprite.flip_h = true

func _physics_process(delta: float) -> void:
	if blimp_state < 2:
		current_time.reset_time()
		var ticks_elapsed = current_time.subtract_ticks(blimp_moveswitch_time)
		if ticks_elapsed <= 1500:
			pass
		var move_choice = rand_range(0, 2)
		position.x += speed * delta
		if position.x > screen_size.x - 80 or position.x < 40:
			if (move_choice <= 1):
				#flip the blimp sprite??
				speed = -speed
				align_blimp(speed)
			else:
				#place the blimp om the opposite side of the game area
				if position.x >= 150:
					position.x = 40
				else:
					position.x = screen_size.x - 120

func _on_Area2D_body_entered(body: Node) -> void:
	var bombchoice = rand_range(0, 5)
	if (bombchoice <= 2) and body.is_in_group("building"):
		emit_signal("bomb")
		bomb_dropped_time.reset_time()
	else:
		if (bombchoice == 3) and body.is_in_group("building-pre1"):
			emit_signal("bomb")
			bomb_dropped_time.reset_time()
		if (bombchoice > 3) and  body.is_in_group("building-pre2"):
			emit_signal("bomb")
			bomb_dropped_time.reset_time()
