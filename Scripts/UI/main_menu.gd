extends Control

@onready var _menu_focus_sound: AudioStreamPlayer = $MenuFocus
@onready var _menu_click_sound: AudioStreamPlayer = $MenuClick
@onready var _canvas = $CanvasLayer
@onready var _title = $MarginContainer/Title
@onready var _splash_text_label = $SplashTextLabel
@onready var _conductor = $Conductor
@onready var _environment: WorldEnvironment = $WorldEnvironment

# Constants for animations that sync to the music.
const SONG: AudioStream = preload("res://Resources/Audio/LevelTracks/Initiate.wav")
const MUSIC_BPM: float = 128
const SECONDS_PER_BEAT: float = 60.0 / MUSIC_BPM
## How often the conductor sends out beat timing events.
const BEAT_TIME: float = SECONDS_PER_BEAT / 2
## How many beats it takes for the bit to cross the screen.
const BIT_TIME_TO_CROSS_SCREEN: float = BEAT_TIME * 8
## The number of pixels below the top of screen/above the bottom of screen that 
## bits can spawn.
const BIT_SPAWN_MARGIN: int = 75
## Once this many bits have been sent, send an enter bit across the screen and 
## reset the interval.
const ENTER_BIT_INTERVAL: int = 15
## Which beat (given by BEAT_TIME) to start pulsing the title.
const START_TITLE_PULSE: int = 12
## Title pulse rate, as the number of beats (given by BEAT_TIME) that have to 
## pass before another title pulse occurs. Cannot be lower than 1.
const TITLE_PULSE_RATE: int = 2

## The strength of blur when in the game settings.
const BACKGROUND_BLUR_STRENGTH: float = 0.5

const splash_text_filepath = "res://Resources/Text/splash_text.json"

# WARNING: if not preloaded this scene can cause a noticable delay (it has to
# load all the level files and display the info).
var _level_select_scene = preload("res://Scenes/UI/level_select.tscn")
var _settings_scene = preload("res://Scenes/UI/settings_ui.tscn")
var _bit = preload("res://Scenes/bit.tscn")

var level_select_node: Control

## The number of bits that have been sent since the last enter bit.
## Start at a different value than zero to offset when the first enter is sent.
var _bit_interval = 2

var _pulse_started := false
var _pulse_title := false
var _pulse_interval = 0

## Dictionary of splash text messages.
var splash_text: Array

## When reloading the menu, will start in the level selection screen if this is
## true.
var start_in_level_select := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Bit.in_main_menu = true
	
	splash_text = _load_splash_text(splash_text_filepath)
	_splash_text_label.text = splash_text[randi_range(0, splash_text.size() - 1)]
	
	# Music.
	_conductor.connect("timed_event", _timed_event)
	_conductor.connect("finished", _start_song)
	_start_song()
	
	# Aesthetics.
	_environment.environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	_environment.environment.glow_bloom = GameSettings.bloom_strength
	
	if start_in_level_select:
		_open_level_select()


## Input handling.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_close_dialog") and level_select_node != null:
		if level_select_node.UI_is_visible():
			level_select_node.hide_UI()
			_show_menu()


## Start the song to play in the main menu.
func _start_song() -> void:
	_conductor.set_song(SONG)
	_conductor.set_timed_event(0)
	_conductor.play_with_offset()


## Controls title bit flickering.
func _process(delta: float) -> void:
	if _pulse_started and _title.modulate.a > 0.5:
		# Divide by 2 since we're only fading to an alpha of 0.5, not 0.
		_title.modulate.a -= delta / BEAT_TIME / TITLE_PULSE_RATE / 2
	
	if _pulse_title: # The conductor send a timing event!
		_pulse_title = false
		# Reset alpha so we can compare this color with the other colors to
		# choose from next (randomly, but with no repeats).
		_title.modulate.a = 1
		
		# Choose a random theme color for the title text.
		var theme_colors = GameSettings.get_theme_colors()
		# Remove the current color from the array.
		theme_colors.remove_at(theme_colors.find(_title.modulate))
		# The same color could exist multiple times, in which case we remove it one
		# more time.
		var double_check = theme_colors.find(_title.modulate)
		if double_check != -1:
			theme_colors.remove_at(double_check)
		
		_title.modulate = theme_colors[randi_range(0, theme_colors.size() - 1)]


## Play effects in time with the menu music.
func _timed_event(event_index: int) -> void:
	_send_random_bit()
	
	# Send the first pulse
	if event_index == START_TITLE_PULSE:
		_pulse_started = true
		_pulse_title = true
	elif event_index >= START_TITLE_PULSE:
		_pulse_interval += 1
		if !_pulse_title and _pulse_interval >= TITLE_PULSE_RATE:
			_pulse_title = true
			_pulse_interval = 0
	
	_conductor.set_timed_event(BEAT_TIME)


## Sends a random bit across the screen, or an enter bit at regular intervals.
func _send_random_bit() -> void:
	var new_bit: Bit = _bit.instantiate()
	# Calculate y value based on the current line number offset from where the
	# cursor started.
	var viewport_height = ProjectSettings.get_setting("display/window/size/viewport_height")
	var y_value = randi_range(BIT_SPAWN_MARGIN, viewport_height - BIT_SPAWN_MARGIN)
	
	var bit_type
	if _bit_interval < ENTER_BIT_INTERVAL:
		_bit_interval += 1
		bit_type = randi_range(0, 1)
	else:
		bit_type = Bit.Type.ENTER
		_bit_interval = 0
	
	add_child(new_bit)
	new_bit.create(bit_type, y_value, 0, BIT_TIME_TO_CROSS_SCREEN, 0)


## Loads the array of splash text messages. Returns nothing if it fails.
func _load_splash_text(filePath: String):
	if FileAccess.file_exists(filePath):
		var data = FileAccess.open(filePath, FileAccess.READ)
		var parsed = JSON.parse_string(data.get_as_text())
		if parsed is Array:
			return parsed
		else:
			push_error("Splash text failed to load!")


## Go into the level select scene. (call this when switching to the menu scene
## to start in the level select scene).
func _open_level_select() -> void:
	_hide_menu()
	
	if level_select_node == null:
		level_select_node = _level_select_scene.instantiate()
		level_select_node.connect("selection_closed", _show_menu)
		add_child(level_select_node)
	else:
		level_select_node.show_UI()


func _on_play_button_pressed() -> void:
	_menu_click_sound.play()
	
	_open_level_select()


func _on_settings_button_pressed() -> void:
	# The bloom slider actually plays the click sound when it's set to the 
	# current value of bloom so we don't need to play it again lol!
	#_menu_click_sound.play()
	
	_hide_menu()
	
	var settings: SettingsUI = _settings_scene.instantiate()
	settings.settings_closed.connect(_show_menu)
	add_child(settings)


## Hide the menu when something else is shown (settings, credits, level select
## etc).
func _hide_menu() -> void:
	_canvas.hide()
	
	# Enable background blur.
	_environment.environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_REPLACE
	_environment.environment.glow_bloom = BACKGROUND_BLUR_STRENGTH


## Show the menu again. Reverses the effects of _hide_menu(). Displays new 
## splash text.
func _show_menu() -> void:
	_canvas.show()
	
	# Disable background blur.
	_environment.environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	_environment.environment.glow_bloom = GameSettings.bloom_strength


func _on_shutdown_button_pressed() -> void:
	get_tree().quit(0)


func _on_play_button_mouse_entered() -> void:
	_menu_focus_sound.play()


func _on_settings_button_mouse_entered() -> void:
	_menu_focus_sound.play()


func _on_shutdown_button_mouse_entered() -> void:
	_menu_focus_sound.play()
