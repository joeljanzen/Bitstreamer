class_name LevelInfo
extends Node
## Stores information about a level.

## The maximum difficulty value a level can have.
const DIFFICULTY_MAX = 12
## The maximum speed value a level can have.
const SPEED_MAX = 12
## The maximum damage value a level can have. This is just to round any damage
## values that are for some reason higher than 100 to be just 100. 100 damage
## instakills, so it's really the max damage that should be saved.
const DAMAGE_MAX = 100

## The file storing the info for this level.
var file_name: String
## The name of the level.
var level_name: String = ""
## The name of the audio file of the song to play.
var song_filename: String = ""
## The actual audio stream for the song of the level.
var song: AudioStream
## The beats per minute of the music (good luck if the song changes bpm bro).
var bpm: float = -1
## The speed at which bits fly across the screen.
var speed: float = -1
## The difficulty of the level, AKA how accurate clicks need to be in order to
## get a perfect score (a good or okay score is also harder to achieve).
var difficulty: float = -1
## The damage each bit does when missed or incorrectly clicked.
## Override damage value to 0 to make the level impossible to fail.
var damage: int = -1
## The length of the level in seconds (how long the gameplay lasts).
var length: float = -1


## Initialize the level button, given its full filename.
func _init(filename: String) -> void:
	file_name = filename
	
	var file = FileAccess.open("res://Levels/%s.txt" % filename, FileAccess.READ)
	
	if file == null:
		push_error("Level file could not be found!")
	else:
		var content = file.get_as_text()
		file.close()
		
		# Will contain empty lines, only so if something goes wrong the correct 
		# line number with the error will be displayed.
		var lines: PackedStringArray = content.split("\n") 
		
		_parse_level_info(lines)
		#if _parse_level_info(lines):
			#if _parse_bits_and_delays(lines):
				## We successfully loaded everything.
				#PerformanceCalculator.set_difficulty(difficulty)
				#
				#bitstream_length = bit_queue.size()
				#
				#if level_length < 0:
					## Calculate the level length and store it in the file, since the
					## file didn't have it yet.
					#level_length = _calc_level_length(delay_queue)
					#if !_save_level_length(file_name, level_length):
						#error_loading = true


## Loads the info for a level, given the lines in the level file.
## Returns true if there were no issues, or false otherwise.
func _parse_level_info(lines: PackedStringArray) -> bool:
	var level_data: PackedStringArray = lines[0].split(",", false)
	var error_loading := false
	
	for tag: String in level_data:
		if tag.contains("name="):
			var check = tag.erase(0, 5) # Erases "name=" from the token.
			if !check.is_empty():
				level_name = check
			else:
				error_loading = true
				push_error("Level name cannot be empty")
				break
		elif tag.contains("bpm="):
			var check = tag.erase(0,4)
			if check.is_valid_float() and float(check) > 0:
				bpm = float(check)
			else:
				error_loading = true
				push_error("%s is not a valid BPM" % check)
				break
		elif tag.contains("speed="):
			var check = tag.erase(0,6)
			if check.is_valid_float() and float(check) >= 1 and float(check) <= SPEED_MAX:
				speed = float(check)
			else:
				error_loading = true
				push_error("%s is not a valid speed" % check)
				break
		elif tag.contains("diff="):
			var check = tag.erase(0,5)
			if check.is_valid_float() and float(check) >= 0 and float(check) <= DIFFICULTY_MAX:
				difficulty = float(check)
			else:
				error_loading = true
				push_error("%s is not a valid difficulty" % check)
				break
		elif tag.contains("dmg="):
			var check = tag.erase(0,4)
			if check.is_valid_int() and int(check) >= 0:
				damage = min(int(check), DAMAGE_MAX)
			else:
				error_loading = true
				push_error("%s is not a valid bit damage" % check)
				break
		elif tag.contains("song="):
			var check = tag.erase(0,5)
			if check.is_valid_filename():
				song_filename = check
			else:
				error_loading = true
				push_error("%s is not a valid song filename" % check)
				break
		elif tag.contains("length="):
			var check = tag.erase(0,7)
			if check.is_valid_float() and float(check) > 0:
				length = float(check)
				
			else:
				error_loading = true
				push_error("%s is not a valid level length" % check)
				break
		else:
			push_error("Level tag not recognized: %s" % tag)
	
	if !error_loading:
		# Check that all data was correctly loaded.
		if level_name.is_empty():
			error_loading = true
			push_error("Level name could not be found!")
		if bpm < 0:
			error_loading = true
			push_error("Level BPM could not be found!")
		if speed < 1:
			error_loading = true
			push_error("Level bit speed could not be found!")
		if difficulty < 0:
			error_loading = true
			push_error("Level difficulty could not be found!")
		if damage < 0:
			error_loading = true
			push_error("Level damage could not be found!")
		if song_filename.is_empty():
			error_loading = true
			push_error("Song audio file could not be found!")
		# Do not check for the level length to be empty here, but we will later, 
		# once the delay queue is loaded. This is because in the case that level
		# length has not been loaded (is not in the file) we can calculate it
		# ourselves using the delay queue values.
	
	if !error_loading: 
		# Try to load the song file.
		song = load("res://Resources/Audio/LevelTracks/%s" % song_filename)
		
		if song == null:
			error_loading = true
			push_error("Song file %s could not be found!" % song_filename)
	
	return !error_loading
