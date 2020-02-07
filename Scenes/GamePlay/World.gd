extends Node2D

var timestamp_class = preload("res://Scripts/Timestamp.gd")
var gamestate_class = preload("res://Scripts/GameState.gd")
var scene_utility_class = preload("res://Scripts/SceneUtility.gd")
var energy_shield_class = preload("res://Scenes/Defense/EnergyShield.tscn")
var blimp_class = preload("res://Scenes/Blimp/Blimp.tscn")

onready var building = $Building
onready var blimp = $Blimp
onready var defence = $Defence

const SHIELD_DURATION = 9000 #6000
const SHIELD_RECHARGE_TIME = 10000 #14000
const GAME_FINISHED_VICTORY = "res://Scenes/GamePlay/OutcomeVictory.tscn"
const GAME_FINISHED_DEFEAT = "res://Scenes/GamePlay/OutcomeGameOver/GameOver.tscn"
const BLIMP_RAIL1 = 60
const BLIMP_RAIL2 = 100
const BLIMP_RAIL3 = 150

var bullet_scene = load("res://Scenes/Bullet/Bullet.tscn")
var bomb_scene = load("res://Scenes/Bomb/Bomb.tscn")
var num_activated_shields = 0
var extra_shield_allowance = false
var screen_size
var map_spawn_blimps = { }
var map_shields_reference = { }
var attack_waves_complete = [ false, false, false] # 3 attack waves for the moment
var blimps_active_session = [ ] # An array that holds the blimps
# that are spawned for a "wave", max 3 blimps can be active
var shield1_activated_time = timestamp_class.timestamp.new()
var shield2_activated_time = timestamp_class.timestamp.new()
var game_start_time = timestamp_class.timestamp.new()
var game_pause_time = timestamp_class.timestamp.new()
var game_current_time = timestamp_class.timestamp.new()
var scene_utility = scene_utility_class.SceneUtility.new()
var game_state_keeper = gamestate_class.GameStateWrapper.new()

func create_test_shields():
	var shield1 = energy_shield_class.instance()
	var shield2 = energy_shield_class.instance()
	var shield3 = energy_shield_class.instance()
	var shield4 = energy_shield_class.instance()
	shield1.position = Vector2(150, 240)
	shield2.position = Vector2(220, 320)
	shield3.position = Vector2(380, 405)
	shield4.position = Vector2(615, 345)
	var shield_array = [shield1, shield2, shield3, shield4]
	for shieldx in shield_array:
		add_child(shieldx)
		shieldx.visible = true
		shieldx.start_deploy()

func _ready() -> void:
	game_start_time.reset_time()
	#blimp.connect("bomb", self, "launch_bomb")
	defence.connect("shoot", self, "shoot")
	shield1_activated_time.reset_time_ticks(-SHIELD_RECHARGE_TIME)
	var screen_size = get_viewport().size
	$player.position = Vector2(140, screen_size.y - 160)
	$player.visible = true
	map_spawn_blimps["default"] = blimp
	preload_blimp_waves()
	#spawn_enemy_blimp("blimp_crimson#2")
	#spawn_enemy_blimp("blimp_velvet#3")
	$"EnergyShield-1".position = Vector2(-1000.0, -500.0) #Must not be placed in the game world, because only clones used
	$GamePlayTimer.start_timer()
	#create_test_shields()

func create_blimp(modcolor : Color):
	var new_blimp = blimp_class.instance()
	if modcolor.r > 0.01 or modcolor.g > 0.01 or modcolor.b > 0.01:
		new_blimp.set_modulate_color(modcolor)
	return new_blimp

func can_activate_shield() -> bool:
	if num_activated_shields <= 0 or (extra_shield_allowance and num_activated_shields <= 1):
		var current_time = timestamp_class.timestamp.new()
		current_time.reset_time()
		var ticks_shield_used = current_time.subtract_ticks(shield1_activated_time)
		if ticks_shield_used >= SHIELD_RECHARGE_TIME:
			return true
	return false

func spawn_enemy_blimp(tag, color, rail_offset, xpos, direction):
	var new_blimp = create_blimp(color)
	new_blimp.position = Vector2(xpos, rail_offset)
	new_blimp.set_direction(direction)
	map_spawn_blimps[tag] = new_blimp

func choose_random_blimp_rail() -> int:
	var rail_choice = int(rand_range(0, 2.05))
	match rail_choice:
		0: return BLIMP_RAIL1
		1: return BLIMP_RAIL2
		2: return BLIMP_RAIL3
	return BLIMP_RAIL1

func preload_blimp_waves():
	screen_size = get_viewport().size
	var xcoord = rand_range(100, 420)
	spawn_enemy_blimp("wave1#1", Color(0, 0, 0), BLIMP_RAIL2, xcoord, 1)
	xcoord = rand_range(40, 310)
	var blimp_rail_offset = choose_random_blimp_rail()
	spawn_enemy_blimp("wave2#1", Color(0.5, 0.275, 0.12), blimp_rail_offset, xcoord, 1)
	xcoord = rand_range(screen_size.x - 160, screen_size.x - 20)
	blimp_rail_offset = choose_random_blimp_rail()
	spawn_enemy_blimp("wave2#2", Color(0.22, 0.32, 0.615), blimp_rail_offset, xcoord, -1)

func launch_blimps_wave(wave_num):
	if wave_num == 1:
		map_spawn_blimps["wave1#1"].set_name("wave1#1")
		map_spawn_blimps["wave1#1"].connect("bomb", self, "launch_bomb")
		map_spawn_blimps["wave1#1"].start_bombing(true)
		add_child(map_spawn_blimps["wave1#1"])
	if wave_num == 2:
		map_spawn_blimps["wave2#1"].set_name("wave2#1")
		map_spawn_blimps["wave2#2"].set_name("wave2#2")
		map_spawn_blimps["wave2#1"].connect("bomb", self, "launch_bomb")
		map_spawn_blimps["wave2#2"].connect("bomb", self, "launch_bomb")
		map_spawn_blimps["wave2#1"].start_bombing(true)
		map_spawn_blimps["wave2#2"].start_bombing(true)
		add_child(map_spawn_blimps["wave2#1"])
		add_child(map_spawn_blimps["wave2#1"])

func _input(event):
	if !event is InputEventKey:
		pass
	screen_size = get_viewport().size
	if Input.is_action_just_pressed("shield_activate"):
		if can_activate_shield():
			#set position for the shield near to player position
			num_activated_shields += 1
			var new_shield = energy_shield_class.instance()
			add_child(new_shield)
			if new_shield != null:
				new_shield.position = Vector2(542.0, 432.0) # y -- 120
				new_shield.visible = true
				new_shield.start_deploy()
				map_shields_reference[num_activated_shields] = new_shield
				shield1_activated_time.reset_time()
				print("World, _input() called with <shield_activate>, new_shield=%s" % [new_shield])
	if Input.is_action_just_pressed("ui_cancel"):
		$GamePlayTimer.set_pause(true)
		game_pause_time.reset_time()

func launch_bomb(blimp_name):
	if blimp_name != null and map_spawn_blimps.has(blimp_name):
		var bomb = bomb_scene.instance()
		bomb.position = map_spawn_blimps[blimp_name].position
		add_child(bomb)

func shoot():
	var bullet = bullet_scene.instance()
	bullet.position = defence.position
	add_child(bullet)

func fortress_destroyed() -> bool:
	return $Building.health_bar.value <= 0.0

func player_killed() -> bool:
	return $player.health <= 0.0

func _on_GameTimer_timeout():
	#Time the blimp and other timer related operations
	game_current_time.reset_time()
	var ticks_game_running = game_current_time.subtract_ticks(game_start_time)
	if ticks_game_running >= 4000 and ticks_game_running < 5000: # Check if wave 1 should be launched
		if attack_waves_complete[0] == false:
			attack_waves_complete[0] = true
			launch_blimps_wave(1)
	if ticks_game_running >= 88000 and ticks_game_running < 89000: # destruct the blimps in wave 1
		pass
	if ticks_game_running >= 90000 and ticks_game_running < 91000: # Check if wave 2 should be launched
		if attack_waves_complete[1] == false:
			attack_waves_complete[1] = true
			launch_blimps_wave(2)
	if num_activated_shields > 0:
		var current_time = timestamp_class.timestamp.new()
		current_time.reset_time()
		var ticks_shield_active = current_time.subtract_ticks(shield1_activated_time)
		if ticks_shield_active >= SHIELD_DURATION:
			var selected_shield = map_shields_reference[num_activated_shields]
			if (selected_shield != null):
				selected_shield.finish_shield_consumed()
			num_activated_shields -= 1
	if (fortress_destroyed() or player_killed()) and (game_state_keeper.game_state != gamestate_class.GameState.GAME_STATE_DEFEAT_START):
		#If one or both are destroyed then you have been defeated - change the game state to GAMESTATE_DEFEAT_START
		game_state_keeper.game_state = gamestate_class.GameState.GAME_STATE_DEFEAT_START
		set_process(false) #only do this when no more visuals or effects to be updated for this game world
		scene_utility.change_scene(self, GAME_FINISHED_DEFEAT)


