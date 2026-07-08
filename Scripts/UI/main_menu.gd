extends Control

@onready var _menu_focus_sound: AudioStreamPlayer = $MenuFocus
@onready var _menu_click_sound: AudioStreamPlayer = $MenuClick
@onready var _canvas = $CanvasLayer
@onready var _title = $MarginContainer/Title
@onready var _splash_text_label = $SplashTextLabel
@onready var _now_playing_label = $MarginContainer2/HBoxContainer/NowPlayingLabel
@onready var _conductor: Conductor = $Conductor
@onready var _environment: WorldEnvironment = $WorldEnvironment

## The number of pixels below the top of screen/above the bottom of screen that 
## bits can spawn.
const BIT_SPAWN_MARGIN: int = 75

## Multiplies itself with the beat speed (given by the song's bpm). A value of 2
## means the beat is registered at twice its normal speed. Bits are sent at this
## speed, while the title pulses in relation to this speed given the 
## TITLE_PULSE_RATE.
const BEAT_COEFFICIENT: int = 2

## Title pulse rate, as the number of beats (affected by the beat coefficient) 
## that have to pass before another title pulse occurs. Cannot be lower than 0.
const TITLE_PULSE_RATE: int = 1

## How much the title fades before it will pulse again. 1 means it fades 
## entirely, while 0 would mean it never fades at all.
const TITLE_FADE_COEFFICIENT: float = 0.5

## The strength of blur when in the game settings.
const BACKGROUND_BLUR_STRENGTH: float = 0.5

const splash_text_filepath = "res://Resources/Text/splash_text.json"

# WARNING: if not preloaded this scene can cause a noticable delay (it has to
# load all the level files and display the info).
var _level_select_scene = preload("res://Scenes/UI/level_select.tscn")
var _settings_scene = preload("res://Scenes/UI/settings_ui.tscn")
var _bit = preload("res://Scenes/bit.tscn")

var level_select_node: Control

# Used in animations that sync to the music.
## How often the conductor sends out beats.
var beat_time: float
## How many beats it takes for the bit to cross the screen.
var bit_time_to_cross_screen: float
## The number of bits that have been sent since the last enter bit.
var _bit_interval: int = 0
## Once this many bits have been sent, send an enter bit across the screen and 
## reset the interval to a new, slightly randomized value.
var _enter_bit_interval: int = 15
## Track how often title pulses.
var title_pulse_interval: int = 0

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
	_conductor.connect("beat", _on_beat)
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
	var info: LevelInfo = LevelInfo.get_random_level_info()
	
	LevelInfo.last_played_in_menu = info
	
	_now_playing_label.text = "Now playing:\n" + info.song_name
	
	beat_time = _conductor.set_beat_signal(info.bpm, BEAT_COEFFICIENT)
	bit_time_to_cross_screen = beat_time * 8
	
	_conductor.set_song(info.song)
	_conductor.play_with_offset()


## Fades title bit alpha. When the title pulses its alpha is reset.
func _process(delta: float) -> void:
	_title.modulate.a -= delta / beat_time / (TITLE_PULSE_RATE + 1) * TITLE_FADE_COEFFICIENT


## Play effects in time with the menu music.
func _on_beat() -> void:
	_send_random_bit()
	
	if title_pulse_interval == 0:
		_pulse_title()
	
	if title_pulse_interval < TITLE_PULSE_RATE:
		title_pulse_interval += 1
	else:
		title_pulse_interval = 0


## Sends a random bit across the screen, or an enter bit at regular intervals.
func _send_random_bit() -> void:
	var new_bit: Bit = _bit.instantiate()
	# Calculate y value based on the current line number offset from where the
	# cursor started.
	var viewport_height = ProjectSettings.get_setting("display/window/size/viewport_height")
	var y_value = randi_range(BIT_SPAWN_MARGIN, viewport_height - BIT_SPAWN_MARGIN)
	
	var bit_type
	if _bit_interval < _enter_bit_interval:
		_bit_interval += 1
		bit_type = randi_range(0, 1)
	else:
		bit_type = Bit.Type.ENTER
		_bit_interval = 0
		_enter_bit_interval = randi_range(4,16)
	
	add_child(new_bit)
	new_bit.create(bit_type, y_value, 0, bit_time_to_cross_screen, 0, _conductor)


## Trigger a title pulse.
func _pulse_title() -> void:
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


func _on_next_song_button_pressed() -> void:
	_start_song()
