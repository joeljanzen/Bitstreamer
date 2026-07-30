extends Node
## Saves and loads the save data resource which contains all persistent game data.

const SAVE_LOCATION = "user://game_save.tres"

var save_data: SaveDataResource = SaveDataResource.new()


## Automatically load game data on start.
func _ready() -> void:
	load_game()


## Save the current state of the game. IMPORTANT: Whenever any value in the 
## save_data resource is modified this function should be called, either right
## away or at some later point, but until it is called a crash/closing the game
## will result in lost data!
func save_game() -> void:
	ResourceSaver.save(save_data, SAVE_LOCATION)


## Load the current state of the game.
func load_game() -> void:
	if FileAccess.file_exists(SAVE_LOCATION):
		save_data = ResourceLoader.load(SAVE_LOCATION).duplicate(true)
