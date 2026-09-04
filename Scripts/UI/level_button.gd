class_name LevelButton
extends Control
## Displays level information and allows clicking to start the level. Includes a
## practice option to start anywhere in the level.

@onready var _button_panel = $ButtonPanel
@onready var _name_label = $ButtonPanel/MarginContainer/VBoxContainer/NamePanel/MarginContainer/VBoxContainer/NameLabel
@onready var _version_label = $ButtonPanel/MarginContainer/VBoxContainer/NamePanel/MarginContainer/VBoxContainer/VersionLabel
@onready var _bit_count_label = $ButtonPanel/MarginContainer/VBoxContainer/LevelDetailsContainer/BitsPanel/MarginContainer/BitCountLabel
@onready var _length_label = $ButtonPanel/MarginContainer/VBoxContainer/LevelDetailsContainer/LengthPanel/MarginContainer/LengthLabel
@onready var _bpm_label = $ButtonPanel/MarginContainer/VBoxContainer/LevelDetailsContainer/BPMPanel/MarginContainer/BPMLabel
@onready var _difficulty_label = $ButtonPanel/MarginContainer/VBoxContainer/LevelDetailsContainer/DifficultyPanel/MarginContainer/DifficultyLabel
@onready var _speed_label = $ButtonPanel/MarginContainer/VBoxContainer/LevelDetailsContainer/SpeedPanel/MarginContainer/SpeedLabel
@onready var _damage_label = $ButtonPanel/MarginContainer/VBoxContainer/LevelDetailsContainer/DamagePanel/MarginContainer/DamageLabel

@onready var _level_image = $ButtonPanel/LevelImage

@onready var _play_practice_container = $ButtonPanel/MarginContainer/VBoxContainer/ButtonContainer
@onready var _play_button = $ButtonPanel/MarginContainer/VBoxContainer/ButtonContainer/PlayButton
@onready var _back_button = $ButtonPanel/MarginContainer/VBoxContainer/ButtonContainer/BackButton
@onready var _practice_button = $ButtonPanel/MarginContainer/VBoxContainer/ButtonContainer/PracticeButton
@onready var _practice_container = $ButtonPanel/MarginContainer/VBoxContainer/ButtonContainer/SliderPanel
@onready var _time_slider_label = $ButtonPanel/MarginContainer/VBoxContainer/ButtonContainer/SliderPanel/MarginContainer/PracticeContainer/TimeSliderLabel
@onready var _time_slider = $ButtonPanel/MarginContainer/VBoxContainer/ButtonContainer/SliderPanel/MarginContainer/PracticeContainer/TimeSlider

@onready var _popup_panel = $PopupPanel
@onready var _popup_label = $PopupPanel/MarginContainer/RichTextLabel

@onready var _launch_animation = $LaunchAnimation


## This level has been focused by clicking on it.
signal button_focused(button: LevelButton)

## This level has been selected to play.
signal launch_button_pressed(level_info: LevelInfo)

## The practice slider has been moved, setting a new level offset.
signal practice_offset_changed(new_offset: float)

## How many seconds it takes a popup to appear after a level attribute started 
## being hovered over.
const _TIME_TO_SHOW_POPUP = 0.5

## This value is how many seconds before the end of the level that the player
## is allowed to start from. This ensures there is at least a little bit of the
## level left if they choose the maximum offset in practice mode.
const _MINIMUM_PLAY_TIME = 5

## How many pixels of vertical mouse drag should be ignored.
## NOTE: It is useful to have the Scroll Deadzone property of the scroll
## container this button is in to be the same value. Otherwise you might be able
## to drag buttons around and also click one at the same time.
const _MOUSE_DRAG_DEADZONE = 35

## The minimum size of the button when it is unfocused.
const _MIN_Y_SIZE = 200

## The maximum size of the button when it is focused.
const _MAX_Y_SIZE = 300

## The alpha value of the level image when the level is unfocused.
const _UNFOCUSED_IMAGE_TRANSPARENCY = 0.2

## The alpha value of the level image when the level is hovered, but not yet
## focused.
const _HOVERED_IMAGE_TRANSPARENCY = 0.5

## The theme color to use for this LevelButton's title color.
## Alternates between true and false each time one is created.
static var use_primary_colour := true

## Level info for this button.
var level_info: LevelInfo

## Level info with modified values from active mods.
var modded_info: LevelInfo

## True the level is to be played in practice mode.
var do_practice := false

## The offset to start the level at in practice, in seconds.
var practice_offset: float = 0

## This level button has been clicked and should be focused.
var is_focused := false

## The initial y position a mouse drag is started from.
## Used to detect if a mouse click is for dragging vertically or just a click.
var _initial_drag_y_pos := 0


## Start a short timer to wait for a popup to start.
var _popup_timer_on := false
var _popup_time: float = 0




## Setup the level button with all level details. Call this after instantiation 
## of the scene but before adding as a child to the current scene tree.
func setup(level_information: LevelInfo) -> void:
	level_info = level_information


## Fills all label text with level info.
func _ready() -> void:
	# For some reason duplication doesn't work at all (spent so long tryna 
	# see why) so I legit uhhh parse the entire level info again ggs.
	#modded_info = level_info.duplicate(DUPLICATE_INTERNAL_STATE) as LevelInfo
	modded_info = LevelInfo.new(level_info.file_name)
	
	_name_label.text = level_info.song_name
	_version_label.text = level_info.version
	_bit_count_label.text = str(level_info.bit_count) + " bits"
	
	if level_info.version != "Tutorial":
		apply_active_mods()
	update_labels()
	
	# Aesthetics
	update_title_color()
	
	if level_info.version == "Tutorial":
		_practice_button.hide()
	
	# Set range for time slider if they wanna practice.
	_time_slider.max_value = level_info.length - _MINIMUM_PLAY_TIME
	
	_set_play_button_text_color()
	
	# Keep the last offset if this is the last level that was played.
	if (LevelInfo.last_played != null 
			and level_info.file_name == LevelInfo.last_played.file_name):
		_time_slider.value = GameLevel.last_offset
	
	# If this level has an associated image, attach it.
	if level_info.has_image():
		_level_image.texture = level_info.get_image()
		_level_image.self_modulate.a = _UNFOCUSED_IMAGE_TRANSPARENCY
		_button_panel.self_modulate.a = 0 # Make the underlying panel invisible.
	else:
		_level_image.hide()
		$ButtonPanel/TextureFade.hide()
		$ButtonPanel/TextureFade2.hide()


## Set popup positions and time when it should show.
func _process(delta: float) -> void:
	if _popup_timer_on and !_popup_panel.visible:
		_popup_time += delta
		if _popup_time > _TIME_TO_SHOW_POPUP:
			_popup_panel.show()
	
	if _popup_panel.visible:
		_popup_panel.global_position.x = get_global_mouse_position().x - 10 - _popup_panel.size.x
		_popup_panel.global_position.y = get_global_mouse_position().y + 10


## Ignore a mouse click if it's the start of a drag. If it is a proper click,
## focus the button.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			_initial_drag_y_pos = event.global_position.y
		elif event.is_released():
			var vertical_distance = abs(_initial_drag_y_pos - event.global_position.y)
			if vertical_distance < _MOUSE_DRAG_DEADZONE:
				# Focus button already checks if the button is focused, but we 
				# need to ensure the sound only plays here when the unfocused 
				# button is clicked, not every time focus_button is called.
				if !is_focused:
					SoundManager.play_menu_click()
					focus_button()


## Focus the level button, which causes some visual changes and emits the
## button_focused signal.
func focus_button() -> void:
	if !is_focused:
		is_focused = true
		button_focused.emit(self)
		
		custom_minimum_size.y = _MAX_Y_SIZE
		scale = Vector2(1.04, 1.04)
		_level_image.self_modulate.a = 1
		
		_play_practice_container.show()


## Press the level button, focusing it but not starting its level.
func defocus_button() -> void:
	if is_focused:
		is_focused = false
		
		size.y = _MIN_Y_SIZE
		custom_minimum_size.y = _MIN_Y_SIZE
		scale = Vector2(1, 1)
		_level_image.self_modulate.a = _UNFOCUSED_IMAGE_TRANSPARENCY
		
		_play_practice_container.hide()


## Update the title color as the theme colors may have been changed.
func update_title_color() -> void:
	if use_primary_colour:
		_name_label.modulate = GameSettings.zero_bit_colour
	else:
		_name_label.modulate = GameSettings.one_bit_colour
	use_primary_colour = !use_primary_colour


## Apply current active mods to update the level button info.
func apply_active_mods() -> void:
	var speed_factor = ModManager.get_playback_speed_factor()
	modded_info.length = level_info.length / speed_factor
	modded_info.bpm = level_info.bpm * speed_factor
	
	modded_info.difficulty = ModManager.apply_difficulty_mods(level_info.difficulty)
	modded_info.damage = ModManager.apply_damage_mods(level_info.damage)
	
	modded_info.speed = ModManager.apply_speed_mods(level_info.speed)
	modded_info.speed = PerformanceCalculator.get_effective_speed(modded_info.speed)


## Update all labels with level info (includes active mods have been applied).
func update_labels() -> void:
	_length_label.text = _float_as_time(modded_info.length)
	_bpm_label.text = _trim_decimals(round(modded_info.bpm)) + " BPM"
	_difficulty_label.text = "Difficulty: " + _trim_decimals(modded_info.difficulty)
	
	_damage_label.text = "Damage: " + str(modded_info.damage)
	
	# A few mods have the potential to lower the speed value below the minimum 
	# or increase it above the normal maximum. Allow the value to increase
	# above the maximum, but it has potential to become negative if the 
	# approach time is very long. Instead, show a speed of zero.
	var display_speed = modded_info.speed
	if modded_info.speed < 0:
		display_speed = 0
	_speed_label.text = "Speed: " + _trim_decimals(display_speed)
	
	# If the practice slider is open, we should update the current value
	# since the level length might have changed.
	if _practice_container.visible:
		_set_slider(_time_slider.value)


## Enable practice mode for the level, showing a slider allowing the player
## to choose where they want to start the level from.
func enable_practice_mode() -> void:
	do_practice = true
	_practice_button.hide()
	_back_button.show()
	_practice_container.show()
	_set_slider(_time_slider.value)
	
	if practice_offset != 0:
		practice_offset_changed.emit(practice_offset)


## update the preview time slider with the given value.
func _set_slider(value: float) -> void:
	practice_offset = value
	
	var mod_factor = modded_info.length / level_info.length
	var value_modded = value * mod_factor
	var progress = value_modded / modded_info.length * 100
	_time_slider_label.text = "Start at %s (%.2f%%)" % [_float_as_time(value_modded), progress]


## Converts the level length in seconds to a string in minutes and seconds.
func _float_as_time(level_length: float) -> String:
	var total_seconds = round(level_length)
	var minutes: int = floor(level_length / 60.0)
	var seconds: int = total_seconds - (minutes * 60)
	
	var string = ""
	if minutes > 0:
		string = str(minutes) + "m"
	
	if seconds > 0:
		if minutes > 0:
			string += " "
		string +=str(seconds) + "s"
	
	if string.is_empty():
		string = "0s"
	
	return string


## If the float has decimal places, it rounds up to 2 places. Otherwise, it 
## includes no decimal places.
func _trim_decimals(value: float) -> String:
	return str(snappedf(value, 0.01)).rstrip("0").rstrip(".")


func _on_play_button_pressed() -> void:
	# Only use an offset if they actually selected practice, duh.
	if _practice_container.visible:
		GameLevel.last_offset = practice_offset
	else:
		GameLevel.last_offset = 0
	launch_button_pressed.emit(level_info)
	
	# Animation
	_launch_animation.play("launch_level")


func _on_play_button_mouse_entered() -> void:
	SoundManager.play_menu_focus()
	_set_play_button_text_color()


## Set the hover color of the button text.
func _set_play_button_text_color() -> void:
	# Choose a random theme color for the button text.
	var theme_colors = GameSettings.get_theme_colors()
	
	# Ideally white should never be chosen as the hover color.
	if theme_colors.size() > 1:
		var white_index = theme_colors.find(Color("ffffff"))
		if white_index > -1:
			theme_colors.remove_at(white_index)
			white_index = theme_colors.find(Color("ffffff"))
			if white_index > -1:
				theme_colors.remove_at(white_index)
	
	# Remove the current color from the array, if there are still multiple colors.
	if theme_colors.size() > 1:
		theme_colors.remove_at(theme_colors.find(_play_button.get_theme_color("font_hover_color")))
		# The same color could exist multiple times, in which case we remove it one
		# more time.
		if theme_colors.size() > 1:
			var final_check = theme_colors.find(_play_button.get_theme_color("font_hover_color"))
			if final_check > -1:
				theme_colors.remove_at(final_check)
	
	_play_button.add_theme_color_override("font_hover_color", theme_colors[randi_range(0, theme_colors.size() - 1)])


## Scale the button and gives it a slight rotation while hovered.
func _on_mouse_entered() -> void:
	if !is_focused:
		SoundManager.play_menu_focus()
		scale = Vector2(1.015, 1.015)
		_level_image.self_modulate.a = _HOVERED_IMAGE_TRANSPARENCY


## Return the button to its default size and rotation.
func _on_mouse_exited() -> void:
	if !is_focused:
		scale = Vector2(1,1)
		# Make the image somwhat transparent.
		_level_image.self_modulate.a = _UNFOCUSED_IMAGE_TRANSPARENCY


## Call when a level attribute is being hovered over. If the cursor remains
## hovering over it, eventually the popup will appear.
func _start_popup_timer() -> void:
	_popup_time = 0
	_popup_timer_on = true


## Call when a level attribute is no longer being hovered over. Hides the popup
## panel and stops the timer. 
func _hide_popup() -> void:
	_popup_panel.hide()
	_popup_timer_on = false


func _on_difficulty_panel_mouse_entered() -> void:	
	_popup_label.text = (
"Difficulty determines the click accuracy required to
get a perfect, good, or okay score, or miss a bit. The 
minimum unmodded difficulty is 0 and the maximum is 12."
	+ "[color=" + GameSettings.perfect_click_colour + "]"
	+ "\n\nPerfect score: +-" + 
	str(int(PerformanceCalculator.get_perfect_click_range(modded_info.difficulty)))
	+ " ms[/color]"
	+ "[color=" + GameSettings.good_click_colour + "]"
	+ "\nGood score: +-" + 
	str(int(PerformanceCalculator.get_good_click_range(modded_info.difficulty)))
	+ " ms[/color]"
	+ "[color=" + GameSettings.okay_click_colour + "]"
	+ "\nOkay score: +-" + 
	str(int(PerformanceCalculator.get_okay_click_range(modded_info.difficulty)))
	+ " ms[/color]"
	+ "[color=" + GameSettings.missed_click_colour + "]"
	+ "\nMiss: >" + 
	str(int(PerformanceCalculator.get_okay_click_range(modded_info.difficulty)))
	+ " ms"
	)
	
	_popup_panel.size = Vector2.ZERO # This forces the panel to resize.
	_start_popup_timer()


func _on_speed_panel_mouse_entered() -> void:
	_popup_label.text = (
"Speed determines how long the bit takes to reach the
cursor after appearing on screen. The minimum unmodded
speed is 1 and the maximum is 12.\n\n"
	+ "[color=" + GameSettings.perfect_click_colour + "]Bit time to cursor: " +
	str(int(PerformanceCalculator.get_approach_time(modded_info.speed) * 1000)) 
	+ " ms"
	)
	
	_popup_panel.size = Vector2.ZERO # This forces the panel to resize.
	_start_popup_timer()


func _on_damage_panel_mouse_entered() -> void:
	_popup_label.text = (
"Damage determines the percentage of program health 
that is lost after missing or incorrectly receiving a bit.
Missing an enter or back bit does not deal damage.\n\n" 
	+ "[color=" + GameSettings.incorrect_click_colour + "]Damage: "
	+ str(modded_info.damage) + "% of total health"
	)
	
	_popup_panel.size = Vector2.ZERO # This forces the panel to resize.
	_start_popup_timer()


func _on_diff_spd_dmg_panel_mouse_exited() -> void:
	_hide_popup()


func _on_practice_button_pressed() -> void:
	SoundManager.play_menu_click()
	enable_practice_mode()


func _on_back_button_pressed() -> void:
	SoundManager.play_menu_click()
	
	do_practice = false
	_back_button.hide()
	_practice_container.hide()
	_practice_button.show()


func _on_time_slider_value_changed(value: float) -> void:
	_set_slider(value)
	practice_offset_changed.emit(practice_offset)


func _on_time_slider_drag_started() -> void:
	SoundManager.play_menu_click()


func _on_button_hovered() -> void:
	SoundManager.play_menu_focus()
