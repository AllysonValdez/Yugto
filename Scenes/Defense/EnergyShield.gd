extends Node2D

var timestamp_class = preload("res://Scripts/Timestamp.gd")
var myState = 0
var shield_collapse_time = timestamp_class.timestamp.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite.visible = false
	$AnimatedSprite.play("default")

func start_deploy():
	visible = true
	$AnimatedSprite.visible = true
	$AnimatedSprite.play("deploy")
	myState = 1

func finish_shield_consumed():
	$AnimatedSprite.play("collapse")
	myState = 3

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (myState == 4):
		var current_time = timestamp_class.timestamp.new()
		current_time.reset_time()
		var ticks_elapsed = current_time.subtract_ticks(shield_collapse_time)
		if ticks_elapsed >= 300:
			visible = false
			$AnimatedSprite.visible = false
			myState = 0
			
	if (myState == 3):
		shield_collapse_time.reset_time()
		myState = 4
