extends StaticBody2D

onready var health_bar = $"HealthBar/HealthBar"

func take_damage(damage):
	print("building")
	health_bar.value -= damage
