extends KinematicBody2D

var group_class = preload("res://Scripts/Group.gd")
var timestamp_class = preload("res://Scripts/Timestamp.gd")

var timestamp_last_missilefired = timestamp_class.timestamp.new()
var current_time = timestamp_class.timestamp.new()

const RELAUNCH_THRESHOLD = 2500 #threshold  time span in milliseconds

signal shoot

func _ready():
	timestamp_last_missilefired.reset_time()

func _physics_process(delta):
	if Input.is_action_pressed("Fire"):
		#only allow a missile to be fired if is after the threshold time span
		current_time.reset_time()
		var ticks_last_fired = current_time.subtract_ticks(timestamp_last_missilefired)
		#print("DefenceMissile, _physics_process, ticks_last_fired=%d" % [ticks_last_fired])
		if ticks_last_fired >= RELAUNCH_THRESHOLD:
			emit_signal("shoot")
			timestamp_last_missilefired.reset_time()
