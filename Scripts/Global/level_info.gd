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

## Stores a reference to the level info of the last level played.
## Useful for restarting levels.
static var last_played: LevelInfo

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

# Level playback information (not loaded by default).
## A queue of upcoming bits.
var bit_queue: Array[Bit.Type]
## A queue of delays between sending bits.
var delay_queue: Array[float]
## The delay between a bit being sent and it reaching the cursor, in seconds.
var _bit_time_to_cursor: float

## Determines if the level information is valid after it's loaded.
var _is_valid := false


## Initialize the level button, given its full filename.
func _init(filename: String) -> void:
	file_name = filename
	
	var file = FileAccess.open("res://Levels/%s" % file_name, FileAccess.READ)
	
	if file == null:
		push_error("Level file could not be found!")
	else:
		var content = file.get_as_text()
		file.close()
		
		# Will contain empty lines, only so if something goes wrong the correct 
		# line number with the error will be displayed.
		var lines: PackedStringArray = content.split("\n") 
		
		if _parse_level_info(lines):
			_is_valid = true


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
		if length < 0:
			error_loading = true
			push_error("Level length could not be found!")
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


## Loads the required bit and delay queues to play a level. Returns true if 
## there were no issues, or false otherwise.
func load_level_bits_and_delays() -> bool:
	var file = FileAccess.open("res://Levels/%s" % file_name, FileAccess.READ)
	var lines: PackedStringArray
	
	if file == null:
		push_error("Level file could not be found!")
		return false
	else:
		var content = file.get_as_text()
		file.close()
		
		# Will contain empty lines, only so if something goes wrong the correct 
		# line number with the error will be displayed.
		lines = content.split("\n") 
	
	var error_loading := false
	
	var seconds_per_beat: float = 60.0 / bpm
	_bit_time_to_cursor = PerformanceCalculator.calculate_approach_time(speed)
	
	for line: int in range(1, lines.size()):
		var line_num = line + 1
		# Ignore commented lines entirely.
		if lines[line].begins_with("#") || lines[line].is_empty():
			continue # This skips to the next iteration of the loop.
		
		var tokens := lines[line].split(",", false)
		if tokens.size() != 2:
			error_loading = true
			push_error("Unexpected number of tokens on line %d: %s" % [line_num, lines[line]])
			break
		
		var delay_token: String = tokens[0]
		var bit_token = tokens[1]
		
		# Treat token as a raw float delay (in seconds).
		if delay_token.begins_with("f"):
			var delay_string = delay_token.erase(0,1)
			if delay_string.is_valid_float():
				delay_queue.push_back(float(delay_string))
			else:
				error_loading = true
		else:
			var fractional_delay = delay_token.split("/", false)
			if fractional_delay.size() == 1:
				# This is just a float, which is the number of beats
				# the delay should be.
				if fractional_delay[0].is_valid_float():
					var delay_value = float(fractional_delay[0]) 
					delay_queue.push_back(delay_value * seconds_per_beat)
				else:
					error_loading = true
			elif fractional_delay.size() == 2:
				# This is a fraction, containing a numerator and denominator
				# indicating the number of beats the delay should be.
				var delay_numerator: float
				var delay_denominator: float
				if fractional_delay[0].is_valid_int():
					delay_numerator = float(fractional_delay[0])
				else:
					error_loading = true
				
				if !error_loading and fractional_delay[1].is_valid_int():
					delay_denominator = float(fractional_delay[1])
				else:
					error_loading = true
				
				if !error_loading:
					delay_queue.push_back(delay_numerator / delay_denominator * seconds_per_beat)
			else:
				error_loading = true
		
		if error_loading:
			push_error("Delay not recognized on line %d: %s" % [line_num, delay_token])
			break
		
		if delay_queue.size() == 1:
			var difference = delay_queue[0] - _bit_time_to_cursor
			if difference < 0:
				error_loading = true
				push_error("First delay of %.2f beats or %.2f seconds on line %d is not long enough due to the bit speed being too low. It should be at least %.2f beats or %.2f seconds long." % 
						[(delay_queue[0] / seconds_per_beat), delay_queue[0], line_num, (_bit_time_to_cursor / seconds_per_beat), _bit_time_to_cursor])
				break
		
		match bit_token:
			"0":
				bit_queue.push_back(Bit.Type.ZERO)
			"1":
				bit_queue.push_back(Bit.Type.ONE)
			"enter":
				bit_queue.push_back(Bit.Type.ENTER)
			"back":
				bit_queue.push_back(Bit.Type.BACK)
			_:
				error_loading = true
				push_error("Bit type not recognized on line %d: %s" % [line_num, bit_token])
				break
	
	if error_loading:
		_is_valid = false
	
	return !error_loading


## Verify that the level information is valid before using it.
func is_valid() -> bool:
	return _is_valid
