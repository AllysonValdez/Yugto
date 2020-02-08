extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func select_wave(wave):
	$"Sprite-Wave1".visible = false
	$"Sprite-Wave2".visible = false
	$"Sprite-Wave3".visible = false
	match wave:
		1: $"Sprite-Wave1".visible = true
		2: $"Sprite-Wave2".visible = true
		3: $"Sprite-Wave3".visible = true

func launch_banner():
	$Timer.start()

func remove_banner():
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_Timer_timeout():
	remove_banner()
