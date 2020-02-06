extends KinematicBody2D

var group_class = preload("res://Scripts/Group.gd")

signal shoot

func _physics_process(delta):
	if Input.is_action_pressed("Fire"):
		emit_signal("shoot")
