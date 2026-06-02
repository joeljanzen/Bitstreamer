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

## True if the UI was visible before pausing.
var _UI_was_visible := true

## The game has been failed.
var failed := false

# Level Information (all loaded from the level's file).
## The name of the level.
var level_name: String = ""
## The beats per minute of the music (good luck if the long changes bpm).
var bpm: float = -1
## The speed at which bits fly across the screen, in pixels per second.
var bit_speed: int = -1
## The difficulty of the level, AKA how accurate clicks need to be in order to
## get a perfect score (a good, or okay score is also harder to achieve).
var difficulty: int = -1
## The damage each bit does when missed or incorrectly clicked.
var damage: int = -1

# Level Playback.
## A queue of upcoming bits.
var bit_queue: Array[Bit.Type]
## A queue of delays between sending bits.
var delay_queue: Array[float]


## Connect to the failed signal.
func _ready() -> void:
	Signals.failed.connect(_failed)

	# Level.
	if load_level("tutorial"):
		print("name: %s" % level_name)
		print("bpm: %s" % bpm)
		print("speed: %s" % bit_speed)
		print("difficulty: %s" % difficulty)
		print("damage: %s" % damage)
		_start_level()
	else:
		print("Level failed to load!")
	
	# Aesthetics.
	_environment.environment.glow_bloom = GameSettings.bloom_strength


## Input handling.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if paused:
			resumed()
		elif not failed:
			_paused()
	elif event.is_action_pressed("toggle level UI") and !paused:
		_levelUI.toggle_visible()


## Load a level, based on its file name.
## Returns if the level loaded successfully.
func load_level(file_name: String) -> bool:
	var file = FileAccess.open("res://Levels/%s.txt" % file_name, FileAccess.READ)
	if file == null:
		push_error("Level file could not be found!")
		return false
	
	var content = file.get_as_text()
	var lines: PackedStringArray = content.split("\n", false)
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
		
		for line in range(1, lines.size()):
			var tokens := lines[line].split(",", false)
			if tokens.size() != 2:
				error_loading = true
				push_error("Unexpected number of tokens in line %d" % line)
				break
			
			var bit_token = tokens[0]
			var delay_token = tokens[1]
			
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
					push_error("Bit type not recognized: %s" % bit_token)
					break
			if delay_token.is_valid_float():
				delay_queue.push_back(float(delay_token))
			else:
				error_loading = true
				push_error("Delay not recognized: %s" % delay_token)
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
		var bit = bit_queue.pop_front()
		print("sending bit of type %d" % bit)
		_play_area.send_bit(bit, bit_speed, damage)
		if !bit_queue.is_empty(): # Ignore the last delay, as the song is done.
			var delay = delay_queue.pop_front()
			print("waiting for %f seconds" % delay)
			_delay_timer.start(delay)
			await _delay_timer.timeout
	# Should actually wait for the last bit to be clicked/missed at this point.
	print("level finished!")


## The level has been unpaused.
func resumed() -> void:
	paused = false
	_delay_timer.set_paused(false)
	
	_pause_instance.queue_free()
	if _UI_was_visible:
		_levelUI.toggle_visible()
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
	
	_UI_was_visible = _levelUI.UI_is_visible()
	_levelUI.hide_UI()
	_play_area.process_mode = Node.PROCESS_MODE_DISABLED
	
	_pause_instance = _pause_screen.instantiate()
	_pause_instance.resumed.connect(resumed)
	add_child(_pause_instance)
	
	# Enable background blur.
	_environment.environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_REPLACE
	_environment.environment.glow_bloom = PAUSE_BLUR_STRENGTH
