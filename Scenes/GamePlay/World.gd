extends Node2D

var timestamp_class = preload("res://Scripts/Timestamp.gd")
var gamestate_class = preload("res://Scripts/GameState.gd")
var scene_utility_class = preload("res://Scripts/SceneUtility.gd")
var energy_shield_class = preload("res://Scenes/Defense/EnergyShield.tscn")
var blimp_class = preload("res://Scenes/Blimp/Blimp.tscn")

onready var building = $Building
onready var blimp = $Blimp
onready var defence = $Defence

const GAME_CLEARANCE_TIMESLOT1 = 60000 # 1 minute below time alllowance
const GAME_CLEARANCE_TIMESLOT2 = 120000
const GAME_SURVIVE_COUNTDOWN = 300000 # 300 seconds -> 5 minutes
const SHIELD_DURATION = 12000
const SHIELD_RECHARGE_TIME = 2500 #8000
const GAME_FINISHED_VICTORY = "res://Scenes/GamePlay/OutcomeVictory.tscn"
const GAME_FINISHED_DEFEAT = "res://Scenes/GamePlay/OutcomeGameOver/GameOver.tscn"
const BLIMP_RAIL1 = 60
const BLIMP_RAIL2 = 100
const BLIMP_RAIL3 = 150
const DEFENSE_TOPUP_BONUS_THRESHOLD = 80

var bullet_scene = load("res://Scenes/Bullet/Bullet.tscn")
var bomb_scene = load("res://Scenes/Bomb/Bomb.tscn")
var num_activated_shields = 0
var extra_shield_allowance = false
var game_win_closeflag = false
var current_attack_wave = 1 #1
var clearance_bonus = 0
var screen_size
var background_music_volume = 0.1
var map_spawn_blimps = { }
var map_shields_reference = { }
var map_early_wave_completion = { }
var map_applied_defense_topup = { }
var attack_waves_complete = [false, false, false] # 3 attack waves for the moment
var blimp_waves_destructed = [false, false, false]
var blimps_active_session = [ ] # An array that holds the blimps
# that are spawned for a "wave", max 3 blimps can be active
var shield1_activated_time = timestamp_class.timestamp.new()
var shield2_activated_time = timestamp_class.timestamp.new()
var game_start_time = timestamp_class.timestamp.new()
var game_finished_time = timestamp_class.timestamp.new()
var game_pause_time = timestamp_class.timestamp.new()
var game_current_time = timestamp_class.timestamp.new()
var check_wave_completion = timestamp_class.timestamp.new()
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

func apply_bonus_defense_topup(wave_num):
	if map_applied_defense_topup.has(wave_num):
		pass
	var defense_ratio = building.health_bar.value / building.get_full_health()
	#print("World, apply_bonus_defense_topup(), wave=%d, defense_ratio=%f" % [wave_num, defense_ratio])
	if defense_ratio >= (DEFENSE_TOPUP_BONUS_THRESHOLD / 100.0):
		pass
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var max_adjust = 0.6
	var min_adjust = 0.4
	match wave_num:
		1:
			min_adjust = 0.3
			max_adjust = 0.5
		2:
			min_adjust = 0.4
			max_adjust = 0.6
		3:
			min_adjust = 0.5
			max_adjust = 0.7
	var defense_topup = rng.randf_range(min_adjust, max_adjust)
	var topup_value = building.health_bar.value + (defense_topup * building.get_full_health())
	if topup_value > (0.9 * building.get_full_health()):
		topup_value = 0.9 * building.get_full_health()
	building.health_bar.value = topup_value
	map_applied_defense_topup[wave_num] = true
	print("World, apply_bonus_defense_topup(), defense_topup=%f" % [defense_topup])

func _ready() -> void:
	game_start_time.reset_time()
	game_finished_time.reset_time()
	check_wave_completion.reset_time()
	randomize()
	defence.connect("shoot", self, "shoot")
	shield1_activated_time.reset_time_ticks(-(SHIELD_RECHARGE_TIME + SHIELD_DURATION + 3000))
	var screen_size = get_viewport().size
	$player.position = Vector2(140, screen_size.y - 160)
	$player.visible = true
	map_spawn_blimps["default"] = blimp
	preload_blimp_waves()
	#spawn_enemy_blimp("blimp_crimson#2")
	#spawn_enemy_blimp("blimp_velvet#3")
	$"EnergyShield-1".position = Vector2(-1000.0, -500.0) #Must not be placed in the game world, because only clones used
	$GamePlayTimer.start_timer()
	load_background_music("res://Assets/Audio/KIAH-RIZALIANO-MIXXX.ogg")
	var musicvolume_percentage = GlobalState.music_volume
	background_music_volume = adjust_proportional_audio_volume(musicvolume_percentage)
	#create_test_shields()

func adjust_proportional_audio_volume(percentage_volume) -> float:
	var res : float = 0.0
	return res

func load_background_music(audio_resource):
	if audio_resource != null:
		#music_audiostream = AudioStream()
		$"AudioStreamPlayer-Music".stream = load(audio_resource)

func play_background_music(play, volume):
	if play:
		$"AudioStreamPlayer-Music".play()
		if volume > 0.0:
			$"AudioStreamPlayer-Music".volume_db = volume
	else:
		$"AudioStreamPlayer-Music".stop()

func create_blimp(modcolor : Color):
	var new_blimp = blimp_class.instance()
	if modcolor.r > 0.01 or modcolor.g > 0.01 or modcolor.b > 0.01:
		new_blimp.set_modulate_color(modcolor)
	return new_blimp

func wave_bonus_shield_extension(wave_num):
	# bonus parcel drops with limited time allowed use ??
	# TO DO : Phase 2
	match wave_num:
		1: return 0
		2: return 3000
		3: return 4000
	return 0

func can_activate_shield() -> bool:
	if num_activated_shields <= 0 or (extra_shield_allowance and num_activated_shields <= 1):
		var current_time = timestamp_class.timestamp.new()
		current_time.reset_time()
		var ticks_shield_used = current_time.subtract_ticks(shield1_activated_time)
		if ticks_shield_used >= SHIELD_RECHARGE_TIME + wave_bonus_shield_extension(current_attack_wave) + SHIELD_DURATION:
			return true
	return false

func spawn_enemy_blimp(tag, color, rail_offset, xpos, direction):
	var new_blimp = create_blimp(color)
	new_blimp.position = Vector2(xpos, rail_offset)
	new_blimp.set_direction(direction)
	map_spawn_blimps[tag] = new_blimp

func choose_random_blimp_rail() -> int:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var rail_choice = rng.randi_range(0, 3)
	match rail_choice:
		0: return BLIMP_RAIL1
		1: return BLIMP_RAIL2
		2: return BLIMP_RAIL3
	return BLIMP_RAIL1

func preload_blimp_waves():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	screen_size = get_viewport().size
	var xcoord = rng.randf_range(100.0, 420.0)
	spawn_enemy_blimp("wave1#1", Color(0, 0, 0), BLIMP_RAIL2, xcoord, 1)
	xcoord = rng.randf_range(40, 310)
	var blimp_rail_offset = choose_random_blimp_rail()
	spawn_enemy_blimp("wave2#1", Color(0.5, 0.275, 0.12), blimp_rail_offset, xcoord, 1)
	xcoord = rng.randf_range(screen_size.x - 160, screen_size.x - 20)
	blimp_rail_offset = choose_random_blimp_rail()
	spawn_enemy_blimp("wave2#2", Color(0.22, 0.32, 0.615), blimp_rail_offset, xcoord, -1)
	xcoord = rng.randf_range(30, 270)
	blimp_rail_offset = choose_random_blimp_rail()
	spawn_enemy_blimp("wave3#1", Color(0.5, 0.275, 0.12), blimp_rail_offset, xcoord, 1)
	xcoord = rng.randf_range(screen_size.x - 140, screen_size.x - 30)
	blimp_rail_offset = choose_random_blimp_rail()
	spawn_enemy_blimp("wave3#2", Color(0.22, 0.32, 0.615), blimp_rail_offset, xcoord, -1)
	xcoord = rng.randf_range(screen_size.x - 450, screen_size.x - 360)
	blimp_rail_offset = choose_random_blimp_rail()
	spawn_enemy_blimp("wave3#3", Color(0.425, 0.85, 0.315), blimp_rail_offset, xcoord, -1)

func destruct_blimp_waves(wave_num):
	if wave_num == 1:
		if map_spawn_blimps["wave1#1"] != null and weakref(map_spawn_blimps["wave1#1"]).get_ref():
			map_spawn_blimps["wave1#1"].destroy_blimp()
			map_spawn_blimps["wave1#1"] = null
	if wave_num == 2:
		if map_spawn_blimps["wave2#1"] != null and weakref(map_spawn_blimps["wave2#1"]).get_ref():
			map_spawn_blimps["wave2#1"].destroy_blimp()
		if map_spawn_blimps["wave2#2"] != null and weakref(map_spawn_blimps["wave2#2"]).get_ref():
			map_spawn_blimps["wave2#2"].destroy_blimp()
		map_spawn_blimps["wave2#1"] = null
		map_spawn_blimps["wave2#2"] = null
	if wave_num == 3:
		if map_spawn_blimps["wave3#1"] != null and weakref(map_spawn_blimps["wave3#1"]).get_ref():
			map_spawn_blimps["wave3#1"].destroy_blimp()
		if map_spawn_blimps["wave3#2"] != null and weakref(map_spawn_blimps["wave3#2"]).get_ref():
			map_spawn_blimps["wave3#2"].destroy_blimp()
		if map_spawn_blimps["wave3#3"] != null and weakref(map_spawn_blimps["wave3#3"]).get_ref():
			map_spawn_blimps["wave3#3"].destroy_blimp()
		map_spawn_blimps["wave3#1"] = null
		map_spawn_blimps["wave3#2"] = null
		map_spawn_blimps["wave3#3"] = null

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
		add_child(map_spawn_blimps["wave2#2"])
	if wave_num == 3:
		map_spawn_blimps["wave3#1"].set_name("wave3#1")
		map_spawn_blimps["wave3#2"].set_name("wave3#2")
		map_spawn_blimps["wave3#3"].set_name("wave3#3")
		map_spawn_blimps["wave3#1"].connect("bomb", self, "launch_bomb")
		map_spawn_blimps["wave3#2"].connect("bomb", self, "launch_bomb")
		map_spawn_blimps["wave3#3"].connect("bomb", self, "launch_bomb")
		map_spawn_blimps["wave3#1"].start_bombing(true)
		map_spawn_blimps["wave3#2"].start_bombing(true)
		add_child(map_spawn_blimps["wave3#1"])
		add_child(map_spawn_blimps["wave3#2"])
		add_child(map_spawn_blimps["wave3#3"])

func check_wave_completion(wave_num):
	#map_early_wave_completion["wave1"] = true -- example
	var blimps_vanquished = 0
	if wave_num == 1:
		if map_spawn_blimps["wave1#1"] == null or !weakref(map_spawn_blimps["wave1#1"]).get_ref():
			map_early_wave_completion["wave1"] = true
	if wave_num == 2:
		if map_spawn_blimps["wave2#1"] == null or !weakref(map_spawn_blimps["wave2#1"]).get_ref():
			blimps_vanquished += 1
		if map_spawn_blimps["wave2#2"] == null or !weakref(map_spawn_blimps["wave2#2"]).get_ref():
			blimps_vanquished += 1
		if blimps_vanquished >= 2:
			map_early_wave_completion["wave2"] = true
	if wave_num == 3:
		if map_spawn_blimps["wave3#1"] == null or !weakref(map_spawn_blimps["wave3#1"]).get_ref():
			blimps_vanquished += 1
		if map_spawn_blimps["wave3#2"] == null or !weakref(map_spawn_blimps["wave3#2"]).get_ref():
			blimps_vanquished += 1
		if map_spawn_blimps["wave3#3"] == null or !weakref(map_spawn_blimps["wave3#3"]).get_ref():
			blimps_vanquished += 1
		if blimps_vanquished >= 3:
			map_early_wave_completion["wave3"] = true

func attack_wave_is_cleared(wave_num) -> bool:
	var key = ""
	match wave_num:
		1:
			key = "wave1"
		2:
			key = "wave2"
		3:
			key = "wave3"
	return map_early_wave_completion.has(key)

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
	if Input.is_action_just_pressed("alt_fire"):
		if $FlakCannon.cooled_down():
			$FlakCannon.fire_volley()
	if Input.is_action_just_pressed("tilt_left") or Input.is_action_just_pressed("tilt_right"):
		#print("World, _input(), event=%s, key=%s" % [event, event.to_string()])
		if event.is_action("tilt_left"):
			$FlakCannon.rotation_to_left()
		if event.is_action("tilt_right"):
			$FlakCannon.rotation_to_right()

func launch_bomb(blimp_name):
	if blimp_name != null and map_spawn_blimps.has(blimp_name):
		var bomb = bomb_scene.instance()
		bomb.connect("shieldhit", self, "_on_bomb_hit_shield")
		bomb.position = map_spawn_blimps[blimp_name].position
		add_child(bomb)

func _on_bomb_hit_shield(bomb_damage):
	#print("World, _on_bomb_hit_shield(), bomb_damage=%f" % [bomb_damage])
	# takes from 0 to 30% of the damage this particular bomb is capable of
	var damage_reduce_factor = 0
	var reduced_damage_cascaded = 0.0
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var damage_reduce_slot = rng.randi_range(0, 2)
	match damage_reduce_slot:
		0: damage_reduce_factor = 0.06
		1: damage_reduce_factor = 0.175
		2: damage_reduce_factor = 0.3
	reduced_damage_cascaded = damage_reduce_factor * bomb_damage
	#print("World, _on_bomb_hit_shield(), reduced damage=%f" % [reduced_damage_cascaded])
	$Building.take_damage(reduced_damage_cascaded)

func shoot():
	var bullet = bullet_scene.instance()
	bullet.position = defence.position
	add_child(bullet)

func fortress_destroyed() -> bool:
	return $Building.health_bar.value <= 0.0

func player_killed() -> bool:
	return $player.health <= 0.0

func intro_wave_banner(wave_num):
	#show an instanced wave banner that shows for X seconds and frees itself (destroy)
	match wave_num:
		1:
			$WaveBanner.visible = true
			$WaveBanner.select_wave(wave_num)
			$WaveBanner.launch_banner()
		2:
			$WaveBanner2.visible = true
			$WaveBanner2.select_wave(wave_num)
			$WaveBanner2.launch_banner()
		3:
			$WaveBanner3.visible = true
			$WaveBanner3.select_wave(wave_num)
			$WaveBanner3.launch_banner()

func _on_GameTimer_timeout():
	#Time the blimp and other timer related operations
	game_current_time.reset_time()
	if current_attack_wave == 4:
		var ticks_game_finished_win = game_current_time.subtract_ticks(game_finished_time)
		#print("World, _on_GameTimer_timeout(), Game Finish, ticks_game_finished_win=%f" % [ticks_game_finished_win])
		if ticks_game_finished_win >= 3000 and game_win_closeflag == false:
			game_win_closeflag = true
			scene_utility.change_scene(self, GAME_FINISHED_VICTORY)
	var ticks_game_running = game_current_time.subtract_ticks(game_start_time)
	if ticks_game_running >= 15000: # Only start checking for wave completion from 15 secs onwards
		var ticks_check_wave_done = game_current_time.subtract_ticks(check_wave_completion)
		if ticks_check_wave_done >= 1000:
			check_wave_completion.reset_time()
			check_wave_completion(current_attack_wave)
	if ticks_game_running >= 4000 and ticks_game_running < 5000: # Check if wave 1 should be launched
		if attack_waves_complete[0] == false:
			attack_waves_complete[0] = true
			intro_wave_banner(1)
			launch_blimps_wave(1)
			play_background_music(true, background_music_volume)
	if ticks_game_running < 87000 and attack_wave_is_cleared(1) and blimp_waves_destructed[0] == false:
		blimp_waves_destructed[0] = true
		apply_bonus_defense_topup(1)
	if ticks_game_running >= 88000 and ticks_game_running < 89000 and blimp_waves_destructed[0] == false: # destruct the blimps in wave 1
		blimp_waves_destructed[0] = true
		destruct_blimp_waves(1)
		apply_bonus_defense_topup(1)
	if (current_attack_wave == 1 and attack_wave_is_cleared(1)) or (ticks_game_running >= 90000 and ticks_game_running < 91000): # Check if wave 2 should be launched
		current_attack_wave = 2
		if attack_waves_complete[1] == false:
			attack_waves_complete[1] = true
			intro_wave_banner(2)
			launch_blimps_wave(2)
	if ticks_game_running < 177000 and attack_wave_is_cleared(2) and blimp_waves_destructed[1] == false:
		blimp_waves_destructed[1] = true
		apply_bonus_defense_topup(2)
	if ticks_game_running >= 178000 and ticks_game_running < 179000 and blimp_waves_destructed[1] == false: # destruct the blimps in wave 2
		blimp_waves_destructed[1] = true
		destruct_blimp_waves(2)
		apply_bonus_defense_topup(2)
	if (current_attack_wave == 2 and attack_wave_is_cleared(2)) or (ticks_game_running >= 180000 and ticks_game_running < 181000): # Wave 3
		current_attack_wave = 3
		if attack_waves_complete[2] == false:
			attack_waves_complete[2] = true
			intro_wave_banner(3)
			launch_blimps_wave(3)
	if blimp_waves_destructed[2] == false:
		# destruct the blimps in wave 3
		if (current_attack_wave >= 3 and attack_wave_is_cleared(3)) or (ticks_game_running >= 299000 and ticks_game_running < 300000):
			print("World, _on_GameTimer_timeout(), wave 3 defeated")
			destruct_blimp_waves(3)
			current_attack_wave = 4
			game_finished_time.reset_time()
			#determine if a significant amount of seconds is still left in the game (countdown) timer
			var ticks_clearance_time = GAME_SURVIVE_COUNTDOWN - ticks_game_running
			print("World, _on_GameTimer_timeout(), ticks_clearance_time (seconds)=%f" % [ticks_clearance_time / 1000.0])
			if ticks_clearance_time >= GAME_CLEARANCE_TIMESLOT1:
				clearance_bonus = 1
			if ticks_clearance_time >= GAME_CLEARANCE_TIMESLOT2:
				clearance_bonus = 2
			blimp_waves_destructed[2] = true
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
		#Wait a few (3 - 4) seconds and then show the "Game Over" screen
		scene_utility.change_scene(self, GAME_FINISHED_DEFEAT)


