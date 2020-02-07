extends Control

var default_control_select = "music"
var current_control_select = default_control_select
var selected_control_index = 0
var total_controls_count = 2

var WORLD_SCENE = "res://Scenes/GamePlay/World.tscn"
var TITLE_SCENE = "res://Scenes/UI/TitleScreen.tscn"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func move_selected_control_direction(direction): #direction of selection is either up or down
	if direction < 0: #moving up
		if selected_control_index > 0:
			selected_control_index -= 1
		else:
			if selected_control_index < total_controls_count:
				selected_control_index += 1

func _input(event):
	if !event is InputEventKey:
		pass
	if Input.is_action_just_pressed("ui_cancel"):
		visible = false
		queue_free()
		get_tree().change_scene(TITLE_SCENE)
	if Input.is_action_just_pressed("ui_up"):
		move_selected_control_direction(-1)
	if Input.is_action_just_pressed("ui_down"):
		move_selected_control_direction(1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
