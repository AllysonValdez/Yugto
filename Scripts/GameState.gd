extends Node

enum GameState { 
	GAME_STATE_START,
	GAME_STATE_PAUSED,
	GAME_STATE_DEFEAT_START,
	GAME_STATE_DEFEAT_COMPLETE
}

class GameStateWrapper:
	var game_state #GameState
	
	func _init():
		game_state = GameState.GAME_STATE_START

	func set_next_state():
		match game_state:
			GameState.GAME_STATE_START:
				game_state = GameState.GAME_STATE_PAUSED
			GameState.GAME_STATE_PAUSED:
				game_state = GameState.GAME_STATE_DEFEAT_START
			GameState.GAME_STATE_DEFEAT_START:
				game_state = GameState.GAME_STATE_DEFEAT_COMPLETE
