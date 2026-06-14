class_name GameLevel
extends Node2D
## A game level, where gameplay occurs and all that jazz.

@onready var _levelUI: GameplayStatistics = $LevelUI
@onready var _environment: WorldEnvironment = $WorldEnvironment
@onready var _play_area: PlayArea = $PlayArea
@onready var _music_queue: Timer = $MusicQueue
@onready var conductor: Conductor = $Conductor

## The strength of blur when the game is paused.
const PAUSE_BLUR_STRENGTH := 0.5

## The maximum difficulty value a level can have.
const DIFFICULTY_MAX = 12
## The maximum speed value a level can have.
const SPEED_MAX = 12

var _crash_screen = preload("res://Scenes/game_crash_ui.tscn")
var _win_screen = preload("res://Scenes/game_win_ui.tscn")
var _pause_screen = preload("res://Scenes/pause_ui.tscn")
var _pause_instance: PauseUI

## The game is paused.
var paused := false

## The game has been failed.
var failed := false

## The game has been completed.
var completed := false

# Level information (all loaded from the level's file).
## The name of the level.
var level_name: String = ""
## The name of the audio file of the song to play.
var song_filename: String = ""
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
var level_length: float = -1
## The number of bits that will be sent in the level.
var bitstream_length: int

# Level playback.
## A queue of upcoming bits.
var bit_queue: Array[Bit.Type]
## A queue of delays between sending bits.
var delay_queue: Array[float]
## The delay between a bit being sent and it reaching the cursor, in seconds.
var bit_time_to_cursor: float
## The audio stream to play out of the music_player.
var song: AudioStream


## Connect to the failed signal and share level statistics with levelUI.
func _ready() -> void:
	Signals.failed.connect(_failed)
	_play_area.no_bits_left.connect(_completed)
	_levelUI.set_UI_visible(GameSettings.level_UI_enabled)
	_levelUI.connect_level(self)

	if load_level("tutorial"):
		print("Successfully loaded level: %s" % level_name)
		print("BPM: %s" % bpm)
		print("Speed: %s" % speed)
		print("Difficulty: %s" % difficulty)
		print("Damage: %s" % damage)
		print("Length: %d seconds" % ceil(level_length))
		print("Bitstream length: %d" % bitstream_length)
		start_level()
	else:
		print("Level failed to load!")
		PerformanceCalculator.set_difficulty(3)
	
	# Aesthetics.
	_environment.environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	_environment.environment.glow_bloom = GameSettings.bloom_strength


## Input handling.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if paused:
			_resumed()
		elif !failed and !completed:
			_paused()
	elif event.is_action_pressed("toggle_level_UI") and !paused and !failed and !completed:
		if _levelUI.UI_is_visible():
			_levelUI.hide_UI()
		else:
			_levelUI.show_UI()
		
		# Update game settings to remember if the player had UI on or not.
		GameSettings.level_UI_enabled = _levelUI.UI_is_visible()


## Load a level, based on its file name (omit .txt from the file name you give).
## Returns if the level loaded successfully.
func load_level(file_name: String) -> bool:
	var file = FileAccess.open("res://Levels/%s.txt" % file_name, FileAccess.READ)
	var error_loading := false
	
	if file == null:
		error_loading = true
		push_error("Level file could not be found!")
	else:
		var content = file.get_as_text()
		file.close()
		
		# Will contain empty lines, only so if something goes wrong the correct 
		# line number with the error will be displayed.
		var lines: PackedStringArray = content.split("\n") 
		
		if !_parse_level_info(lines):
			error_loading = true
		elif !_parse_bits_and_delays(lines):
			error_loading = true
		else: # We successfully loaded almost everything.
			PerformanceCalculator.set_difficulty(difficulty)
			
			bitstream_length = bit_queue.size()
			
			if level_length < 0:
				# Calculate the level length and store it in the file, since the
				# file didn't have it yet.
				level_length = _calc_level_length(delay_queue)
				if !_save_level_length(file_name, level_length):
					error_loading = true
	return !error_loading


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
				damage = int(check)
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
				level_length = float(check)
				
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


## Loads the info for a level, given the lines in the level file.
## Returns true if there were no issues, or false otherwise.
func _parse_bits_and_delays(lines: PackedStringArray) -> bool:
	var error_loading := false
	
	var seconds_per_beat: float = 60.0 / bpm
	bit_time_to_cursor = PerformanceCalculator.set_approach_time(speed)
	
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
			var difference = delay_queue[0] - bit_time_to_cursor
			if difference < 0:
				error_loading = true
				push_error("First delay of %.2f beats or %.2f seconds on line %d is not long enough due to the bit speed being too low. It should be at least %.2f beats or %.2f seconds long." % 
						[(delay_queue[0] / seconds_per_beat), delay_queue[0], line_num, (bit_time_to_cursor / seconds_per_beat), bit_time_to_cursor])
				break
		
		match bit_token:
			"0":
				bit_queue.push_back(Bit.Type.ZERO)
			"1":
				bit_queue.push_back(Bit.Type.ONE)
			"enter":
				bit_queue.push_back(Bit.Type.ENTER)
			"2":
				bit_queue.push_back(Bit.Type.ENTER)
			_:
				error_loading = true
				push_error("Bit type not recognized on line %d: %s" % [line_num, bit_token])
				break
	
	return !error_loading


## Returns the length of the level, given its delay queue.
## Uses 3 decimal places of precision.
func _calc_level_length(level_delay_queue: Array[float]) -> float:
	var length = level_delay_queue.reduce(func(sum, number): return sum + number, 0)
	return snapped(length, 0.001)


## Saves the level length to the specified level file, returning if the length
## was saved successfully.
func _save_level_length(file_name: String, length: float) -> bool:
	var file = FileAccess.open("res://Levels/%s.txt" % file_name, FileAccess.READ_WRITE)
	var error_loading := false
	
	if file == null:
		error_loading = true
		push_error("Level file could not be found!")
	else:
		var first_line: String = file.get_line()
		file.seek(0) # Go back to the start of the file after getting that line.
		var content: String = file.get_as_text()
		
		# Erase the first line entirely from content (it will be replaced later)
		content = content.erase(0, content.find("\n", 0) + 1)
		
		# Write over the first line of the file, now with the level length.
		var updated_first_line = first_line + ",length=" + str(length) + "\n"
		
		# Append the first line back and store everything back into the file.
		var full_file = content.insert(0, updated_first_line)
		if !file.store_string(full_file):
			error_loading = true
			push_error("Level length could not be saved to file!")
	file.close()
	return !error_loading


## Starts the music for the level. Optionally, an offset in seconds can be 
## given, which will skip to that point in the level and play from there.
## Must successfully call load_level with no errors for this func to work.
func start_level(level_offset: float = 0) -> void:
	_levelUI.set_level_length(level_length)
	conductor.set_song(song)
	conductor.timed_event.connect(_receive_timed_event)

	# The total time in the song when the next bit should be sent.
	# We want to find when the total time is greater than the offset seconds.
	# This will also give us the delay for the initial timed event.
	var total_time = -bit_time_to_cursor 
	var event_index = -1
	var curr_line = 1
	var next_enters = [] # the times the upcoming enters are considered clicked
	while total_time < level_offset and event_index < delay_queue.size() - 1:
		event_index += 1
		
		# An enter is far enough along that it will not be sent so we must
		# consider it clicked.
		if !next_enters.is_empty() and total_time >= next_enters[0]:
			next_enters.pop_front()
			curr_line += 1
			if curr_line > _play_area.MAX_LINE_NUM:
				curr_line = 1
		
		total_time += delay_queue[event_index]
		
		if bit_queue[event_index] == Bit.Type.ENTER:
			# Cannot understand how this appears to work ngl.
			next_enters.push_back(total_time - bit_time_to_cursor)
	
	if total_time < level_offset:
		push_error("An offset of %.2f goes past the entire level!" % level_offset)
	else:
		 # This sets the cursor to the exact line it would be at that point in the
		 # level.
		_play_area.override_line_num(curr_line)
		
		conductor.set_timed_event(total_time)
		conductor.play_with_offset(level_offset, event_index)


## The next timed event has been received by the conductor. Sends the next bit
## and sets up the delay to the next timed event.
func _receive_timed_event(event_index: int) -> void:
	#print("TIMED EVENT OF INDEX %d RECEIVED AT %s" % [event_index, _conductor.get_time()])
	var bit: Bit.Type = bit_queue[event_index]
	var dmg: int = damage
	if bit == Bit.Type.ENTER:
		dmg = 0
	_play_area.send_bit(bit, bit_time_to_cursor, dmg)
	
	var delay_queue_index = event_index + 1
	if delay_queue_index < delay_queue.size():
		var delay = delay_queue[delay_queue_index]
		conductor.set_timed_event(delay)
	else:
		# Tell play_area that all bits are sent, then wait for the final bit to
		# be clicked/missed (the no_bits_left signal will be emitted).
		_play_area.last_bits_sent()


## The level has been unpaused.
func _resumed() -> void:
	paused = false
	_music_queue.set_paused(false)
	conductor.toggle_paused()
	
	_pause_instance.queue_free()
	_levelUI.set_UI_visible(GameSettings.level_UI_enabled)
	_levelUI.process_mode = Node.PROCESS_MODE_INHERIT
	_play_area.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Disable background blur.
	_environment.environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	_environment.environment.glow_bloom = GameSettings.bloom_strength


## The level has been paused.
func _paused() -> void:
	paused = true
	_music_queue.set_paused(true)
	conductor.toggle_paused()
	
	_levelUI.hide_UI()
	_levelUI.process_mode = Node.PROCESS_MODE_DISABLED
	_play_area.process_mode = Node.PROCESS_MODE_DISABLED
	
	_pause_instance = _pause_screen.instantiate()
	_pause_instance.resumed.connect(_resumed)
	add_child(_pause_instance)
	
	# Enable background blur.
	_environment.environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_REPLACE
	_environment.environment.glow_bloom = PAUSE_BLUR_STRENGTH


## The level has been failed.
func _failed() -> void:
	failed = true
	_levelUI.process_mode = Node.PROCESS_MODE_DISABLED
	_play_area.process_mode = Node.PROCESS_MODE_DISABLED
	conductor.done_timings()
	
	var crash_screen: GameCrashUI = _crash_screen.instantiate()
	crash_screen.connect_gameplay_stats(_levelUI)
	add_child(crash_screen)


## The level has been completed.
func _completed() -> void:
	completed = true
	_levelUI.process_mode = Node.PROCESS_MODE_DISABLED
	_play_area.process_mode = Node.PROCESS_MODE_DISABLED
	conductor.done_timings()
	
	_levelUI.hide_UI()
	
	# Enable background blur.
	_environment.environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_REPLACE
	_environment.environment.glow_bloom = PAUSE_BLUR_STRENGTH
	
	var win_screen: GameWinUI = _win_screen.instantiate()
	win_screen.connect_gameplay_stats(_levelUI)
	add_child(win_screen)
