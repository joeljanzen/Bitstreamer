extends Node
## Saves and loads the save data resource which contains all persistent game 
## data. Also for saving and loading level plays.

## Where save data is stored.
const SAVE_DATA_LOCATION = "user://game_save.tres"

## The folder where all level plays are stored.
const SAVE_PLAYS_LOCATION = "user://plays"

var save_data: SaveDataResource = SaveDataResource.new()


## Automatically load game data on start.
func _ready() -> void:
	# Create the plays directory if it doesn't exist.
	if !DirAccess.dir_exists_absolute(SAVE_PLAYS_LOCATION):
		DirAccess.make_dir_absolute(SAVE_PLAYS_LOCATION)
	
	load_game()


## Save the current state of the game. IMPORTANT: Whenever any value in the 
## save_data resource is modified this function should be called, either right
## away or at some later point, but until it is called a crash/closing the game
## will result in lost data!
func save_game() -> void:
	ResourceSaver.save(save_data, SAVE_DATA_LOCATION)


## Load the current state of the game.
func load_game() -> void:
	if FileAccess.file_exists(SAVE_DATA_LOCATION):
		save_data = ResourceLoader.load(SAVE_DATA_LOCATION).duplicate(true)


## Save a completed play.
func save_play(level_info: LevelInfo, play_data: PlayData) -> void:
	var play_directory = SAVE_PLAYS_LOCATION + "/" + level_info.get_filename_without_type()
	
	# Create the directory for this level if it doesn't exist
	if !DirAccess.dir_exists_absolute(play_directory):
		DirAccess.make_dir_absolute(play_directory)
	
	# Name play files for a level by the order they are saved
	var play_number: int = DirAccess.get_files_at(play_directory).size()
	var play_file = play_directory + "/play_" + str(play_number) + ".tres"
	
	ResourceSaver.save(play_data, play_file)


## Request to the ResourceLoader to load the plays for the given levels.
## Get these plays with load_plays().
func request_plays(all_level_info: Array[LevelInfo]) -> void:
	for level_info: LevelInfo in all_level_info:
		var play_directory = SAVE_PLAYS_LOCATION + "/" + level_info.get_filename_without_type()
		
		if DirAccess.dir_exists_absolute(play_directory):
			var num_plays: int = DirAccess.get_files_at(play_directory).size()
			
			# Start from last play so newer plays are requested first.
			for i in range(num_plays - 1, -1, -1):
				var play_file = play_directory + "/play_" + str(i) + ".tres"
				# could try using subthreads
				ResourceLoader.load_threaded_request(play_file, "PlayData")


## Loads all completed plays for a level, in order of most to least recent.
## Returns an empty array if there are no plays.
func load_plays(level_info: LevelInfo) -> Array[PlayData]:
	var play_data_array: Array[PlayData] = []
	var play_directory = SAVE_PLAYS_LOCATION + "/" + level_info.get_filename_without_type()
	
	if DirAccess.dir_exists_absolute(play_directory):
		var num_plays: int = DirAccess.get_files_at(play_directory).size()
		
		# Start from last play so older plays are added to back of array.
		for i in range(num_plays - 1, -1, -1):
			var play_file = play_directory + "/play_" + str(i) + ".tres"
			var data: PlayData = ResourceLoader.load_threaded_get(play_file).duplicate(true)
			play_data_array.push_back(data)
	
	return play_data_array
