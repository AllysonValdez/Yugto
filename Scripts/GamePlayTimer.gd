extends Control

var timestamp_class = preload("res://Scripts/Timestamp.gd")

const GAME_VICTORY_SECONDS = 5 * 60 # The game clock to beat in seconds - default 5 minutes == 300 seconds
var secondsElapsed = 0
var ticksElapsed = 0
var previousTicksElapsed = 4
var is_game_paused = false
var game_timer_started = timestamp_class.timestamp.new()
var current_game_time = timestamp_class.timestamp.new()

signal timer_finished

# Called when the node enters the scene tree for the first time.
func _ready():
	game_timer_started.reset_time()
	current_game_time.reset_time()

func start_timer():
	$Timer.start()

func stop_timer():
	$Timer.stop()

func set_pause(pause):
	is_game_paused = pause

func game_victory():
	#Switch to the victory image scene
	stop_timer()
	#change_scene(VICTORY_SCENE)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !$Timer.is_stopped() and !is_game_paused:
		#Get the seconds difference between current time and start time
		ticksElapsed = current_game_time.subtract_ticks(game_timer_started)
		if (ticksElapsed != previousTicksElapsed):
			previousTicksElapsed = ticksElapsed
			#print("GamePlayTimer process(), ticks elapsed=%d" % [ticksElapsed] )
			var ticks_elapsed_seconds = ticksElapsed / 1000.0
			var min_elapsed = int(ticks_elapsed_seconds / 60.0)
			var time_elapsed_printout = "%02d M %02d S" % [ min_elapsed, int(ticks_elapsed_seconds) % 60]
			$"Panel/Label-Time-Counter".text = time_elapsed_printout
			if int(ticks_elapsed_seconds) >= GAME_VICTORY_SECONDS:
				game_victory()

func _on_Timer_timeout():
	current_game_time.reset_time()
	#print("GamePlayTimer _on_Timer_timeout(), updating current time")
