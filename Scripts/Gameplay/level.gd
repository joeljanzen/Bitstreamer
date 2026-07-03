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

var _crash_screen = preload("res://Scenes/UI/game_crash_ui.tscn")
var _win_screen = preload("res://Scenes/UI/game_win_ui.tscn")
var _pause_screen = preload("res://Scenes/UI/pause_ui.tscn")
var _pause_instance: PauseUI

## The game is paused.
var paused := false

## The game has been failed.
var failed := false

## The game has been completed.
var completed := false

var level_info: LevelInfo

# Level playback.
## A queue of upcoming bits.
var bit_queue: Array[Bit.Type]
## A queue of delays between sending bits.
var delay_queue: Array[float]
## The delay between a bit being sent and it reaching the cursor, in seconds.
var bit_time_to_cursor: float


## Connect to the failed and completed signal and connect the conductor to levelUI.
func _ready() -> void:
	Signals.failed.connect(_failed)
	_play_area.no_bits_left.connect(_completed)
	_levelUI.set_UI_visible(GameSettings.level_UI_enabled)
	_levelUI.connect_conductor(conductor)
	
	if level_info == null:
		level_info = LevelInfo.last_played
	
	bit_queue = level_info.bit_queue
	delay_queue = level_info.delay_queue
	
	start_level()
	
	# Aesthetics.
	_environment.environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	_environment.environment.glow_bloom = GameSettings.bloom_strength


## Input handling.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and !paused and !failed and !completed:
		_paused()
	elif event.is_action_pressed("toggle_level_UI") and !paused and !failed and !completed:
		if _levelUI.UI_is_visible():
			_levelUI.hide_UI()
		else:
			_levelUI.show_UI()
		
		# Update game settings to remember if the player had UI on or not.
		GameSettings.level_UI_enabled = _levelUI.UI_is_visible()


## Set which level to play when the scene loads. Otherwise the last played
## level will be reloaded.
func set_level(level_information: LevelInfo) -> void:
	level_info = level_information


## Starts the music for the level. Optionally, an offset in seconds can be 
## given, which will skip to that point in the level and play from there.
## Must successfully call load_level with no errors for this func to work.
func start_level(level_offset: float = 0) -> void:
	_levelUI.set_level_length(level_info.length)
	
	PerformanceCalculator.set_difficulty(level_info.difficulty)
	bit_time_to_cursor = PerformanceCalculator.set_approach_time(level_info.speed)
	
	conductor.set_song(level_info.song)
	conductor.timed_event.connect(_recieve_timed_event)

	# The total time in the song when the next bit should be sent.
	# We want to find when the total time is greater than the offset seconds.
	# This will also give us the delay for the initial timed event.
	var total_time = -bit_time_to_cursor 
	var event_index = -1
	var curr_line = 1
	# Keep track up enter and back bits, since they cannot be counted as clicked
	# right away.
	var enter_next = false
	var back_next = false
	
	while total_time < level_offset and event_index < delay_queue.size() - 1:
		event_index += 1
		
		# An enter or back bit is far enough along that it will not be sent so 
		# we must consider it clicked.
		if enter_next:
			curr_line += 1
			if curr_line > _play_area.MAX_LINE_NUM:
				curr_line = 1
			enter_next = false
		if back_next:
			curr_line -= 1
			if curr_line < 1:
				curr_line = 1
			back_next = false
		
		total_time += delay_queue[event_index]
		
		if bit_queue[event_index] == Bit.Type.ENTER:
			enter_next = true
		if bit_queue[event_index] == Bit.Type.BACK:
			back_next = true
	
	if total_time < level_offset:
		push_error("An offset of %.2f goes past the entire level!" % level_offset)
	else:
		 # This sets the cursor to the exact line it would be at that point in 
		 # the level.
		_play_area.override_line_num(curr_line)
		
		conductor.play_with_offset(level_offset, event_index)
		conductor.set_timed_event(total_time)


## The next timed event has been recieved by the conductor. Sends the next bit
## and sets up the delay to the next timed event.
func _recieve_timed_event(event_index: int) -> void:
	#print("TIMED EVENT OF INDEX %d RECEIVED AT %s" % [event_index, _conductor.get_time()])
	var bit: Bit.Type = bit_queue[event_index]
	var dmg: int = level_info.damage
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
	
	_play_area.set_cursor_animation(GameSettings.cursor_flicker)
	_play_area.update_border_color()
	
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
