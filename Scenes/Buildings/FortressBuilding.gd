extends StaticBody2D

onready var health_bar = $"HealthBar/HealthBar"
var full_health

func _ready():
	full_health = health_bar.value

func take_damage(damage):
	print("building")
	health_bar.value -= damage

func get_full_health():
	return full_health
