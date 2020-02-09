extends KinematicBody2D

var timestamp_class = preload("res://Scripts/Timestamp.gd")
var flak_bullet_class = preload("res://Scenes/Bullet/FlakScatter.tscn")

var current_anim = "default"

enum CannonRotate { 
	CANNON_ROTATE_UP,
	CANNON_ROTATE_LEFT_HORIZON,
	CANNON_ROTATE_RIGHT_HORIZON,
	CANNON_ROTATE_LEFT_15DEGREES,
	CANNON_ROTATE_LEFT_30DEGREES,
	CANNON_ROTATE_RIGHT_15DEGREES,
	CANNON_ROTATE_RIGHT_30DEGREES,
}

const COOLDOWN = 1000

var current_rotate_position = CannonRotate.CANNON_ROTATE_UP
var current_time = timestamp_class.timestamp.new()
var cannon_fired_time = timestamp_class.timestamp.new()
var cannon_fired = false

# Called when the node enters the scene tree for the first time.
func _ready():
	current_time.reset_time()
	cannon_fired_time.reset_time()

func play_animation():
	if (current_anim != null):
		$"Animated-Selections".play(current_anim)

func rotation_to_left():
	match current_rotate_position:
		CannonRotate.CANNON_ROTATE_UP:
			pivot_flakcannon(CannonRotate.CANNON_ROTATE_LEFT_15DEGREES)
		CannonRotate.CANNON_ROTATE_LEFT_15DEGREES:
			pivot_flakcannon(CannonRotate.CANNON_ROTATE_LEFT_30DEGREES)
		CannonRotate.CANNON_ROTATE_RIGHT_15DEGREES:
			pivot_flakcannon(CannonRotate.CANNON_ROTATE_UP)
		CannonRotate.CANNON_ROTATE_RIGHT_30DEGREES:
			pivot_flakcannon(CannonRotate.CANNON_ROTATE_RIGHT_15DEGREES)

func rotation_to_right():
	match current_rotate_position:
		CannonRotate.CANNON_ROTATE_UP:
			pivot_flakcannon(CannonRotate.CANNON_ROTATE_RIGHT_15DEGREES)
			pass
		CannonRotate.CANNON_ROTATE_RIGHT_15DEGREES:
			pivot_flakcannon(CannonRotate.CANNON_ROTATE_RIGHT_30DEGREES)
			pass
		CannonRotate.CANNON_ROTATE_LEFT_15DEGREES:
			pivot_flakcannon(CannonRotate.CANNON_ROTATE_UP)
			pass
		CannonRotate.CANNON_ROTATE_LEFT_30DEGREES:
			pivot_flakcannon(CannonRotate.CANNON_ROTATE_LEFT_15DEGREES)

func pivot_flakcannon(rotatepos):
	current_rotate_position = rotatepos
	print("FlakCannon, pivot_flakcannon(), rotatepos=%s" % [rotatepos])
	var rotate_value = 0
	match current_rotate_position:
		CannonRotate.CANNON_ROTATE_UP:
			rotate_value = 0
		CannonRotate.CANNON_ROTATE_LEFT_HORIZON:
			rotate_value = -90
		CannonRotate.CANNON_ROTATE_RIGHT_HORIZON:
			rotate_value = 90
		CannonRotate.CANNON_ROTATE_LEFT_15DEGREES:
			rotate_value = -15
		CannonRotate.CANNON_ROTATE_LEFT_30DEGREES:
			rotate_value = -30
		CannonRotate.CANNON_ROTATE_RIGHT_15DEGREES:
			rotate_value = 15
		CannonRotate.CANNON_ROTATE_RIGHT_30DEGREES:
			rotate_value = 30
	rotation_degrees = rotate_value

func cooled_down() -> bool:
	current_time.reset_time()
	var ticks_fire_check = current_time.subtract_ticks(cannon_fired_time)
	return ticks_fire_check >= COOLDOWN

func fire_volley():
	cannon_fired = true
	cannon_fired_time.reset_time()
	current_anim = "fire"
	#trigger flak cluster ammunition
	play_animation()
	var bullet_instance = flak_bullet_class.instance()
	bullet_instance.visible = true
	bullet_instance.position.y = -140.0
	add_child(bullet_instance)
	bullet_instance.fire()

func _process(delta):
	current_time.reset_time()
	if cannon_fired:
		var ticks_fire_check = current_time.subtract_ticks(cannon_fired_time)
		if ticks_fire_check > 500:
			cannon_fired = false
			current_anim = "default"
			play_animation()
