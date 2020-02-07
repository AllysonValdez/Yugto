extends Node2D

var timestamp_class = preload("res://Scripts/Timestamp.gd")

onready var building = $Building
onready var blimp = $Blimp
onready var defence = $Defence

const SHIELD_DURATION = 9000 #6000
const SHIELD_RECHARGE_TIME = 10000 #14000
const GAME_FINISHED_VICTORY = "res://Scenes/GamePlay/OutcomeVictory.tscn"
const GAME_FINISHED_DEFEAT = "res://Scenes/GamePlay/OutcomeDefeated.tscn"

var bullet_scene = load("res://Scenes/Bullet/Bullet.tscn")
var bomb_scene = load("res://Scenes/Bomb/Bomb.tscn")
var num_activated_shields = 0
var map_spawn_blimps = { }
var blimps_active_session = [ ] # An array that holds the blimps
# that are spawned for a "wave", max 3 blimps can be active
var shield1_activated_time = timestamp_class.timestamp.new()
var shield2_activated_time = timestamp_class.timestamp.new()
var game_pause_time = timestamp_class.timestamp.new()

func _ready() -> void:
	blimp.connect("bomb", self, "launch_bomb")
	defence.connect("shoot", self, "shoot")
	shield1_activated_time.reset_time()
	var screen_size = get_viewport().size
	$player.position = Vector2(140, screen_size.y - 160)
	$player.visible = true
	map_spawn_blimps["default"] = blimp
	spawn_enemy_blimp("blimp_crimson#2")
	spawn_enemy_blimp("blimp_velvet#3")
	$GamePlayTimer.start_timer()

func clone_blimp():
	return blimp.duplicate()

func can_activate_shield() -> bool:
	if (num_activated_shields <= 0):
		var current_time = timestamp_class.timestamp.new()
		current_time.reset_time()
		var ticks_shield_used = current_time.subtract_ticks(shield1_activated_time)
		if ticks_shield_used >= SHIELD_RECHARGE_TIME:
			return true
	return false

func spawn_enemy_blimp(tag):
	var new_blimp = clone_blimp()
	map_spawn_blimps[tag] = new_blimp

func _input(event):
	if !event is InputEventKey:
		pass
	if Input.is_action_just_pressed("shield_activate"):
		if can_activate_shield():
			#set position for the shield near to player position
			num_activated_shields += 1
			$"EnergyShield-1".start_deploy()
			shield1_activated_time.reset_time()
	if Input.is_action_just_pressed("ui_cancel"):
		$GamePlayTimer.set_pause(true)
		game_pause_time.reset_time()

func launch_bomb():
	var bomb = bomb_scene.instance()
	bomb.position = blimp.position
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
	if num_activated_shields > 0:
		var current_time = timestamp_class.timestamp.new()
		current_time.reset_time()
		var ticks_shield_active = current_time.subtract_ticks(shield1_activated_time)
		if ticks_shield_active >= SHIELD_DURATION:
			$"EnergyShield-1".finish_shield_consumed()
			num_activated_shields -= 1
	if fortress_destroyed() or player_killed():
		#If one or both are destroyed then you have been defeated
		#scene_utility.change_scene()
		pass

