extends Node
## Holds game settings for the player. These persist throughout levels.
## May also include global constants that are only meant for devs to modify.

## The location of the file where the default settings are saved and loaded.
const DEFAULTS_FILEPATH: String = "user://default_settings.cfg"

## The location of the file where player settings are saved and loaded.
const USER_SETTINGS_FILEPATH: String = "user://user_settings.cfg"

## The number of seconds to wait before triggering a finish state for the level.
const LEVEL_FINISH_DELAY: float = 0.5

# Gameplay settings.
## Displays an effect indicating the acccuracy of the bit click (or miss).
## If disabled, bits just fade away when clicked.
var bit_click_effect := true

## Ignores the bit click effect for perfect clicks, regardless of the bit click 
## effect being enabled.
var ignores_perfect_clicks = false

## When true if a bit is missed it moves off screen. Otherwise it disappears.
var move_offscreen_on_bit_miss := true

## How quickly the bit fades away after being clicked (in seconds).
## Setting to 0 disables fade entirely.
## Make sure to disable the bit click effect for all bits to fade instead of 
## disappear. This affects perfect clicks regardless of the effect being 
## enabled if perfect clicks are set to be ignored.
var clicked_fade_time: float = 0.15

## The cursor flickers like a real cursor. Set false to disable flickering.
var cursor_flicker := true

## Toggles the level UI during gameplay.
var level_UI_enabled := true

# Video settings.
## The strength of bloom.
var bloom_strength: float = 0.5

## Toggles Flowerwall CRT shader. Use set_crt_effect() to change it, do not
## manually change this value!
var crt_filter := true
## The CRT shader singleton.
var _crt_shader: flowerwallCRT

## Whether the game is in fullscreen or not.
var fullscreen := true

# Theme colours.
## The colour of zero bits.
var zero_bit_colour := Color("#00FF00")
## The colour of one bits.
var one_bit_colour := Color("#FF0066")
## The colour of enter bits.
var enter_bit_colour := Color("#FFFFFF")
## The colour of back bits.
var back_bit_colour := Color("#FFFFFF")

# Other colours the user can't actually change.
## The colour displayed for correctly entered bits on the terminal.
var entered_bit_colour := "#454545"
## The colour displayed for incorrectly entered bits on the terminal.
var missed_bit_colour := "#454545"
## The colour displayed for incorrectly entered bits on the terminal.
var incorrect_bit_colour := "#330000"

## The colour associated with perfect clicks.
var perfect_click_colour := "FF66FF"
## The colour associated with good clicks.
var good_click_colour := "3399FF"
## The colour associated with okay clicks.
var okay_click_colour := "FFCC00"
## The colour associated with missed clicks.
var missed_click_colour := "FFFFFF"
## The colour associated with incorrect clicks.
var incorrect_click_colour := "FF0000"

## Can check to ensure the main menu only loads game settings when the game is 
## first opened.
var game_loaded := false


## Connect the Flowerwall CRT script when it is loaded.
func connect_crt_shader(crt_shader: flowerwallCRT) -> void:
	_crt_shader = crt_shader


## Set the CRT filter on or off.
func set_crt_filter(enabled: bool) -> void:
	crt_filter = enabled
	if enabled:
		_crt_shader.enable_shader()
	else:
		_crt_shader.disable_shader()


## Set the window to fullscreen or windowed mode.
func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	if enabled:
		get_window().mode = Window.MODE_FULLSCREEN
	else:
		get_window().mode = Window.MODE_WINDOWED


## Returns an array of all theme colors used in UI, in order of primary, 
## secondary, and so on.
func get_theme_colors() -> Array[Color]:
	return [zero_bit_colour, one_bit_colour, enter_bit_colour]


## Save the current game settings to a config file. To save the default
## settings, pass true.
func save_settings(save_defaults: bool = false) -> void:
	var config: ConfigFile = ConfigFile.new()
	
	config.set_value("video_settings", "bloom_strength", bloom_strength)
	config.set_value("video_settings", "crt_filter", crt_filter)
	config.set_value("video_settings", "fullscreen", fullscreen)
	
	config.set_value("audio_settings", "master_volume", 
		AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Master")))
	config.set_value("audio_settings", "music_volume", 
		AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Music")))
	config.set_value("audio_settings", "gameplay_volume", 
		AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Gameplay")))
	config.set_value("audio_settings", "menu_volume", 
		AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Menu")))
	
	config.set_value("gameplay_settings", "bit_click_effect", bit_click_effect)
	config.set_value("gameplay_settings", "ignores_perfect_clicks", ignores_perfect_clicks)
	config.set_value("gameplay_settings", "move_offscreen_on_bit_miss", move_offscreen_on_bit_miss)
	config.set_value("gameplay_settings", "clicked_fade_time", clicked_fade_time)
	config.set_value("gameplay_settings", "cursor_flicker", cursor_flicker)
	config.set_value("gameplay_settings", "level_UI_enabled", level_UI_enabled)
	
	# Only saves a single keybind per action.
	for action: String in GameControls.BINDABLE_ACTIONS:
		var events = InputMap.action_get_events(action)
		config.set_value("controls_settings", action, events[0])
		
		#var index = 0
		#for keybind: InputEvent in events:
			#config.set_value("controls_settings", action + str(index), keybind)
			#index += 1
		# This will have issues when trying to load because you don't know how
		# many keybinds have been saved for a single action
	
	config.set_value("theme_settings", "zero_bit_colour", zero_bit_colour)
	config.set_value("theme_settings", "one_bit_colour", one_bit_colour)
	config.set_value("theme_settings", "enter_bit_colour", enter_bit_colour)
	config.set_value("theme_settings", "back_bit_colour", back_bit_colour)
	
	if save_defaults:
		config.save(DEFAULTS_FILEPATH)
	else:
		config.save(USER_SETTINGS_FILEPATH)


## Load all user settings from a config file.
func load_user_settings() -> void:
	var config = ConfigFile.new()
	
	var error = config.load(USER_SETTINGS_FILEPATH)
	
	if error != OK:
		push_error("Settings file could not be opened and loaded!")
		return
	
	_load_video_settings(config)
	_load_audio_settings(config)
	_load_gameplay_settings(config)
	_load_controls_settings(config)
	_load_theme_settings(config)
	
	game_loaded = true


## Load default settings for the current settings tab provided ONLY. All 
## settings in other tabs remain unchanged.
## 0 is video, 1 is audio, 2 is gameplay, 3 is controls, 4 is theme.
func load_default_settings(tab_index: int) -> void:
	var config = ConfigFile.new()
	var error = config.load(DEFAULTS_FILEPATH)
	if error != OK:
		push_error("Settings file could not be opened and loaded!")
		return
	
	match tab_index:
		0:
			_load_video_settings(config)
		1:
			_load_audio_settings(config)
		2:
			_load_gameplay_settings(config)
		3:
			_load_controls_settings(config)
		4:
			_load_theme_settings(config)

# Self explanatory functions that load different settings, given the config file.
# These are separated so that default settings can be individually loaded from 
# each without changing the others.

func _load_video_settings(config: ConfigFile) -> void:
	bloom_strength = config.get_value("video_settings", "bloom_strength")
	set_crt_filter(config.get_value("video_settings", "crt_filter"))
	set_fullscreen(config.get_value("video_settings", "fullscreen"))


func _load_audio_settings(config: ConfigFile) -> void:
	var volume = config.get_value("audio_settings", "master_volume")
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume))
	volume = config.get_value("audio_settings", "music_volume")
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(volume))
	volume = config.get_value("audio_settings", "gameplay_volume")
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Gameplay"), linear_to_db(volume))
	volume = config.get_value("audio_settings", "menu_volume")
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Menu"), linear_to_db(volume))


func _load_gameplay_settings(config: ConfigFile) -> void:
	bit_click_effect = config.get_value("gameplay_settings", "bit_click_effect")
	ignores_perfect_clicks = config.get_value("gameplay_settings", "ignores_perfect_clicks")
	move_offscreen_on_bit_miss = config.get_value("gameplay_settings", "move_offscreen_on_bit_miss")
	clicked_fade_time = config.get_value("gameplay_settings", "clicked_fade_time")
	cursor_flicker = config.get_value("gameplay_settings", "cursor_flicker")
	level_UI_enabled = config.get_value("gameplay_settings", "level_UI_enabled")


func _load_controls_settings(config: ConfigFile) -> void:
	# Only loads a single keybind per action.
	for action: String in GameControls.BINDABLE_ACTIONS:
		var event = config.get_value("controls_settings", action)
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)


func _load_theme_settings(config: ConfigFile) -> void:
	zero_bit_colour = config.get_value("theme_settings", "zero_bit_colour")
	one_bit_colour = config.get_value("theme_settings", "one_bit_colour")
	enter_bit_colour = config.get_value("theme_settings", "enter_bit_colour")
	back_bit_colour = config.get_value("theme_settings", "back_bit_colour")
