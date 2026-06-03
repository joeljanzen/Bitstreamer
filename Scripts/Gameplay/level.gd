extends Node2D
## A game level, where gameplay occurs and all that jazz.

@onready var _levelUI: LevelStatistics = $LevelUI
@onready var _environment: WorldEnvironment = $WorldEnvironment
@onready var _play_area: PlayArea = $PlayArea
@onready var _delay_timer: Timer = $DelayTimer

## The strength of blur when the game is paused.
const PAUSE_BLUR_STRENGTH := 0.5

var _crash_screen = preload("res://Scenes/game_crash_ui.tscn")
var _pause_screen = preload("res://Scenes/pause_ui.tscn")
var _pause_instance: PauseUI

## The game is paused.
var paused := false

## The game has been failed.
var failed := false

# Level information (all loaded from the level's file).
## The name of the level.
var level_name: String = ""
## The beats per minute of the music (good luck if the song changes bpm bro).
var bpm: float = -1
## The speed at which bits fly across the screen, in pixels per second.
var bit_speed: int = -1
## The difficulty of the level, AKA how accurate clicks need to be in order to
## get a perfect score (a good, or okay score is also harder to achieve).
var difficulty: int = -1
## The damage each bit does when missed or incorrectly clicked.
var damage: int = -1

# Level playback.
## A queue of upcoming bits.
var bit_queue: Array[Bit.Type]
## A queue of delays between sending bits.
var delay_queue: Array[float]


## Connect to the failed signal.
func _ready() -> void:
	Signals.failed.connect(_failed)
	
	_levelUI.set_UI_visible(GameSettings.level_UI_enabled)

	# Level.
	if load_level("tutorial_example"):
		print("name: %s" % level_name)
		print("bpm: %s" % bpm)
		print("speed: %s" % bit_speed)
		print("difficulty: %s" % difficulty)
		print("damage: %s" % damage)
		_start_level()
	else:
		print("Level failed to load!")
	
	# Aesthetics.
	_environment.environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	_environment.environment.glow_bloom = GameSettings.bloom_strength


## Input handling.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if paused:
			_resumed()
		elif not failed:
			_paused()
	elif event.is_action_pressed("toggle level UI") and !paused and !failed:
		if _levelUI.UI_is_visible():
			_levelUI.hide_UI()
		else:
			_levelUI.show_UI()
		
		# Update game settings to remember if the player had UI on or not.
		GameSettings.level_UI_enabled = _levelUI.UI_is_visible()


## Load a level, based on its file name.
## Returns if the level loaded successfully.
func load_level(file_name: String) -> bool:
	var file = FileAccess.open("res://Levels/%s.txt" % file_name, FileAccess.READ)
	if file == null:
		push_error("Level file could not be found!")
		return false
	
	var content = file.get_as_text()
	# Will contain empty lines, only so if something goes wrong the correct line
	# number with the error will be displayed.
	var lines: PackedStringArray = content.split("\n") 
	var level_data: PackedStringArray = lines[0].split(",", false)
	
	var error_loading := false
	
	for token: String in level_data:
		if token.contains("name="):
			level_name = token.erase(0, 5) # Erases "name=" from the token.
		elif token.contains("bpm="):
			var check = token.erase(0,4)
			if check.is_valid_float():
				bpm = float(check)
		elif token.contains("speed="):
			var check = token.erase(0,6)
			if check.is_valid_int():
				bit_speed = int(check)
		elif token.contains("diff="):
			var check = token.erase(0,5)
			if check.is_valid_int():
				difficulty = int(check)
		elif token.contains("dmg="):
			var check = token.erase(0,4)
			if check.is_valid_int():
				damage = int(check)
		else:
			push_error("Level data not recognized: %s" % token)
	
	# Check that all data was correctly loaded.
	if level_name.is_empty():
		error_loading = true
		push_error("Level name could not be found!")
	if bpm < 0:
		error_loading = true
		push_error("Level BPM could not be found!")
	if bit_speed < 0:
		error_loading = true
		push_error("Level bit speed could not be found!")
	if difficulty < 0:
		error_loading = true
		push_error("Level difficulty could not be found!")
	if damage < 0:
		error_loading = true
		push_error("Level damage could not be found!")
	
	if !error_loading:
		print("Made it to the bit loading part!")
		
		var seconds_per_beat: float = 1.0 / bpm * 60.0
		print("Seconds per beat is %f" % seconds_per_beat)
		
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
	
	if error_loading:
		return false
	else:
		print("Successfully loaded all bits and delays!\n")
		print(bit_queue)
		print()
		print(delay_queue)
		print()
		return true


## Starts the level, provided that the level has been loaded correctly.
func _start_level() -> void:
	while !bit_queue.is_empty():
		var delay = delay_queue.pop_front()
		print("waiting for %f seconds" % delay)
		_delay_timer.start(delay)
		await _delay_timer.timeout
		
		var bit = bit_queue.pop_front()
		print("sending bit of type %d" % bit)
		_play_area.send_bit(bit, bit_speed, damage)
	
	# Should actually wait for the last bit to be clicked/missed at this point.
	print("level finished!")


## The level has been unpaused.
func _resumed() -> void:
	paused = false
	_delay_timer.set_paused(false)
	
	_pause_instance.queue_free()
	_levelUI.set_UI_visible(GameSettings.level_UI_enabled)
	_play_area.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Disable background blur.
	_environment.environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	_environment.environment.glow_bloom = GameSettings.bloom_strength


## The level has been failed.
func _failed() -> void:
	failed = true
	_delay_timer.stop()
	_play_area.process_mode = Node.PROCESS_MODE_DISABLED
	
	var crash_screen: GameCrashUI = _crash_screen.instantiate()
	crash_screen.connect_stats(_levelUI)
	add_child(crash_screen)


## The level has been paused.
func _paused() -> void:
	paused = true
	_delay_timer.set_paused(true)
	
	_levelUI.hide_UI()
	_play_area.process_mode = Node.PROCESS_MODE_DISABLED
	
	_pause_instance = _pause_screen.instantiate()
	_pause_instance.resumed.connect(_resumed)
	add_child(_pause_instance)
	
	# Enable background blur.
	_environment.environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_REPLACE
	_environment.environment.glow_bloom = PAUSE_BLUR_STRENGTH
