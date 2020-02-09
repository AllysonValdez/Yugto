extends KinematicBody2D

signal health_updated(health)
signal killed()

const MOVE_SPEED = 500
const JUMP_FORCE = 1120
const GRAVITY = 42
const MAX_FALL_SPEED = 960

export (float) var max_health = 100

onready var anim_player = $AnimationPlayer
onready var sprite = $Sprite

onready var health = max_health setget _set_health

var y_velo = 0
var facing_right = false
var previous_position = Vector2(0, 0)

func _ready():
	play_anim("idle")
	set_physics_process(true)

func _physics_process(delta):
	var move_dir = 0
	if Input.is_action_pressed("move_right"):
		move_dir += 1
	if Input.is_action_pressed("move_left"):
		move_dir -= 1
	move_and_slide(Vector2(move_dir * MOVE_SPEED,y_velo), Vector2(0,-1))
	if (previous_position != position):
		var screen_size = get_viewport().size
		previous_position = position
		if position.x >= screen_size.x - 1 or position.x <= 0:
			position.x = clamp(position.x, 0, screen_size.x - 1)
		#print("Player _physics_process, position=%s" % [position])
	
	var grounded = is_on_floor()
	y_velo += GRAVITY
	if grounded and Input.is_action_just_pressed("jump"):
		y_velo = -JUMP_FORCE
	if grounded and y_velo >= 5:
		y_velo = 5
	if y_velo > MAX_FALL_SPEED:
		y_velo = MAX_FALL_SPEED
	
	if facing_right and move_dir < 0:
		flip()
	if !facing_right and move_dir > 0:
		flip()
		
	if grounded:
		if move_dir == 0:
			play_anim("idle")
		else:
			play_anim("Walk")
	else:
		play_anim("jump")
	
func flip():
	facing_right = !facing_right
	sprite.flip_h = !sprite.flip_h
	
func play_anim(anim_name):
	if anim_player.is_playing() and anim_player.current_animation == anim_name:
		return
	anim_player.play(anim_name)
	
func damage(amount):
	_set_health (health - amount)
	
func kill():
	pass
	
func _set_health(value):
	var prev_health = health
	health = clamp(value,0,max_health)
	if health != prev_health:
		emit_signal("health_updated", health)
		if health == 0:
			kill()
			emit_signal("killed")
