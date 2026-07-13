extends GameLevel
## A tutorial level, with hardcoded sections to give the player practice

@onready var dialogue_scene = preload("res://Scenes/UI/dialogue.tscn")

var _dialogue_box: Dialogue

## Connect to the failed and completed signal and connect the conductor to levelUI.
func _ready() -> void:
	_play_area.no_bits_left.connect(_completed)
	_levelUI.set_UI_visible(false)
	_levelUI.connect_conductor(conductor)
	
	# When a new level chosen, it is set to last_played before this scene 
	# instantiates, so in all cases this works fine.
	level_info = LevelInfo.last_played
	
	bit_queue = level_info.bit_queue
	delay_queue = level_info.delay_queue
	
	# Setup before we can start sending bits.
	_levelUI.set_level_length(level_info.length)
	PerformanceCalculator.set_difficulty(level_info.difficulty)
	bit_time_to_cursor = PerformanceCalculator.set_approach_time(level_info.speed)
	conductor.timed_event.connect(_receive_timed_event)
	conductor.set_song(level_info.song)
	_play_area.set_process_input(false)
	
	# Initiate dialogue.
	_dialogue_box = dialogue_scene.instantiate()
	var canvas = CanvasLayer.new()
	canvas.add_child(_dialogue_box)
	add_child(canvas)
	_dialogue_box.display_dialogue("start")
	_dialogue_box.connect("dialogue_exited", _start_level)
	
	# Aesthetics.
	_environment.environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	_environment.environment.glow_bloom = GameSettings.bloom_strength


## Input handling.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and !paused and !completed:
		_paused()


## Starts the music for the level. Optionally, an offset in seconds can be 
## given, which will skip to that point in the level and play from there.
## Must successfully call load_level with no errors for this func to work.
func _start_level(level_offset: float = 0) -> void:
	_play_area.set_process_input(true)
	
	# The total time in the song when the next bit should be sent.
	# We want to find when the total time is greater than the offset seconds.
	# This will also give us the delay for the initial timed event.
	var total_time = -bit_time_to_cursor 
	var event_index = -1
	
	while total_time < level_offset and event_index < delay_queue.size() - 1:
		event_index += 1
		total_time += delay_queue[event_index]
	
	if total_time < level_offset:
		push_error("An offset of %.2f goes past the entire level!" % level_offset)
	else:
		conductor.play_with_offset(level_offset, event_index)
		conductor.set_timed_event(total_time)

## The level has been paused.
func _paused() -> void:
	super() # call parent paused function.
	_dialogue_box.hide()
	_dialogue_box.pause_dialogue()


## The level has been unpaused.
func _resumed() -> void:
	super() # call parent resumed function.
	
	_levelUI.hide_UI()
	if _dialogue_box.sequence_active:
		_dialogue_box.show()
		_dialogue_box.resume_dialogue()
