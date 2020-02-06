extends Node2D

func _ready():
	$"MarginContainer/VBoxContainer/VBoxContainer/Button-Menu-Play".grab_focus()
	$MarginContainer/HBoxContainer/OptionButton.grab_focus()
	
func _physics_process(_delta):
	if $"MarginContainer/VBoxContainer/VBoxContainer/Button-Menu-Play".is_hovered() == true:
		$"MarginContainer/VBoxContainer/VBoxContainer/Button-Menu-Play".grab_focus()
	if $"MarginContainer/VBoxContainer/VBoxContainer/Button-Menu-Quit".is_hovered() == true:
		$"MarginContainer/VBoxContainer/VBoxContainer/Button-Menu-Quit".grab_focus()
	if $MarginContainer/HBoxContainer/OptionButton.is_hovered() == true:
		$MarginContainer/HBoxContainer/OptionButton.grab_focus()

func _on_TextureButton_pressed():
	print("TitleScreen, _on_TextureButton_pressed(), changing scene to ... World.tscn")
	get_tree().change_scene("res://Scenes/GamePlay/World.tscn")

func _on_OptionButton_pressed():
	print("TitleScreen, _on_OptionButton_pressed(), changing scene to ... OptionsMenu.tscn")
	get_tree().change_scene("res://Scenes/UI/OptionsMenu/OptionsMenu.tscn")

func _on_TextureButton2_pressed():
	get_tree().quit()
