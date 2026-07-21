extends GameLevel
## A tutorial level, with hardcoded sections to give the player practice

@onready var dialogue_scene = preload("res://Scenes/UI/dialogue.tscn")

@onready var tutorial_s2_music = preload("res://Resources/Audio/LevelTracks/Tutorial S2.wav")
@onready var tutorial_s3_music = preload("res://Resources/Audio/LevelTracks/Tutorial S3.wav")

## Tells the tutorial how long each section is. The last section goes to the
## end of the bit and delay queues.
const _SECTION_END_INDEX = [8, 17]

## How many mistakes the player can make without being forced to retry the 
## section.
const _SECTION_SUCCESS_THRESHOLD = [2, 1, 1]

var _dialogue_box: Dialogue

## Tracks which section the player is currently on.
var _current_section: int = 1

## Connect to the failed and completed signal and connect the conductor to levelUI.
func _ready() -> void:
	_play_area.no_bits_left.connect(_section_end)
	# Hide elements individually so we can slowly reveal them.
	_levelUI.show_UI()
	_levelUI.set_accuracy_label_visible(false)
	_levelUI.set_combo_label_visible(false)
	_levelUI.set_health_bar_visible(false)
	_levelUI.set_level_progress_visible(false)
	_levelUI.set_score_label_visible(false)
	
	_levelUI.connect_conductor(conductor)
	
	# When a new level chosen, it is set to last_played before this scene 
	# instantiates, so in all cases this works fine.
	level_info = LevelInfo.last_played
	
	bit_queue = level_info.bit_queue
	delay_queue = level_info.delay_queue
	
	# Setup before we can start sending bits.
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
	_dialogue_box.dialogue_exited.connect(_start_level)
	_dialogue_box.dialogue_event.connect(_dialogue_event)
	_dialogue_box.display_dialogue("start")
	
	# Aesthetics.
	_environment.environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	_environment.environment.glow_bloom = GameSettings.bloom_strength


## Input handling.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and !paused and !completed:
		_paused()
	elif event.is_action_pressed("restart"):
		restart(get_tree())


## Starts the music for the level. Optionally, an offset in seconds can be 
## given, which will skip to that point in the level and play from there.
## Must successfully call load_level with no errors for this func to work.
func _start_level(level_offset: float = 0) -> void:
	_play_area.set_process_input(true)
	_play_area._clear_bit_label_lines()
	_play_area.override_line_num(0)
	
	# Always reset stats so this section is not affected by the last.
	_levelUI.reset_stats()
	
	var event_index = 0
	if _current_section > 1:
		event_index = _SECTION_END_INDEX[_current_section - 2] + 1
	var total_time = delay_queue[event_index] - bit_time_to_cursor 
	
	# Calculate level length for just this section
	var level_length = 0
	if _current_section < _SECTION_SUCCESS_THRESHOLD.size():
		for i in range(event_index, _SECTION_END_INDEX[_current_section - 1] + 1):
			level_length += delay_queue[i]
	else:
		for i in range(event_index, delay_queue.size()):
			level_length += delay_queue[i]
	_levelUI.set_level_length(level_length)
	_levelUI.set_level_progress_visible(true)
	
	if total_time < level_offset:
		push_error("An offset of %.2f goes past the entire level!" % level_offset)
	else:
		# Set new music for new sections.
		match _current_section:
			2:
				conductor.set_song(tutorial_s2_music)
				
			3:
				conductor.set_song(tutorial_s3_music)
		
		conductor.play_with_offset(level_offset, event_index)
		conductor.set_timed_event(total_time)


## The next timed event has been received by the conductor. Sends the next bit
## and sets up the delay to the next timed event.
func _receive_timed_event(event_index: int) -> void:
	if _current_section == _SECTION_SUCCESS_THRESHOLD.size(): 
		# Use the default func for the last section.
		super(event_index)
	else: 
		# Have to end before we reach end of the queues for earlier sections.
		var bit: Bit.Type = bit_queue[event_index]
		var dmg: int = level_info.damage
		if bit == Bit.Type.ENTER:
			dmg = 0
		_play_area.send_bit(bit, bit_time_to_cursor, dmg, conductor)
		
		var delay_queue_index = event_index + 1
		
		if event_index < _SECTION_END_INDEX[_current_section - 1]:
			var delay = delay_queue[delay_queue_index]
			conductor.set_timed_event(delay)
		else:
			_play_area.last_bits_sent()


## The section has been completed. It may restart if there were misses, but
## otherwise it will proceed to the next tutorial section.
func _section_end() -> void:
	await get_tree().create_timer(GameSettings.LEVEL_FINISH_DELAY).timeout
	
	_play_area.set_process_input(false)
	_levelUI.set_level_progress_visible(false)
	_play_area.set_cursor_animation(GameSettings.cursor_flicker)
	
	match _current_section:
		1:
			if (_levelUI.missed_clicks + _levelUI.error_clicks > 
						_SECTION_SUCCESS_THRESHOLD[0]):
				_dialogue_box.display_dialogue("fail_start")
			else:
				_current_section += 1
				_dialogue_box.display_dialogue("enter_bit")
				_levelUI.set_score_label_visible(true)
		2:
			if (_levelUI.missed_clicks + _levelUI.error_clicks > 
						_SECTION_SUCCESS_THRESHOLD[1]):
				_dialogue_box.display_dialogue("fail_enter_bit")
			else:
				_current_section += 1
				_dialogue_box.display_dialogue("back_bit")
				_levelUI.set_health_bar_visible(true)
		3:
			if (_levelUI.missed_clicks + _levelUI.error_clicks > 
						_SECTION_SUCCESS_THRESHOLD[1]):
				_dialogue_box.display_dialogue("fail_back_bit")
			else:
				_dialogue_box.dialogue_exited.disconnect(_start_level)
				_dialogue_box.dialogue_exited.connect(_completed)
				_dialogue_box.display_dialogue("finish")
				pass


## The level has been paused.
func _paused() -> void:
	super() # call parent paused function.
	_dialogue_box.hide()
	_dialogue_box.pause_dialogue()


## The level has been unpaused.
func _resumed() -> void:
	super() # call parent resumed function.
	
	if _dialogue_box.sequence_active:
		_dialogue_box.show()
		_dialogue_box.resume_dialogue()


## A dialogue event has been received.
func _dialogue_event(event_name: String) -> void:
	match event_name:
		"show_combo":
			_levelUI.set_combo_label_visible(true)


## The tutorial has been completed successfully.
func _completed() -> void:
	var menu_scene = load("res://Scenes/UI/main_menu.tscn").instantiate()
	menu_scene.start_in_level_select = true
	get_tree().change_scene_to_node(menu_scene)
