extends Node

const VICTORY_SCENE = "SCENE_EXTRA_VICTORY"
const DEFEATED_SCENE = "SCENE_EXTRA_DEFEATED"

const GAME_FINISHED_DEFEAT = "res://Scenes/GamePlay/OutcomeGameOver/GameOver.tscn"
const GAME_FINISHED_VICTORY = "res://Scenes/GamePlay/OutcomeVictory/VectoryScene.tscn"

class SceneUtility:
	#dictionary of predefined scenes
	var defined_scenes = { }
	
	func _init():
		add_defined_scene(VICTORY_SCENE, GAME_FINISHED_VICTORY)
		add_defined_scene(DEFEATED_SCENE, GAME_FINISHED_DEFEAT)

	func add_defined_scene(key, scene):
		defined_scenes[key] = scene

	func change_scene(child_scene, scene_resource):
		print("SceneUtility, change_scene(), scene resource=%s" % [scene_resource])
		child_scene.get_tree().change_scene(scene_resource)
