class_name LevelButton
extends Control

@onready var _button_panel = $Panel
@onready var _name_label = $Panel/MarginContainer/VBoxContainer/NamePanel/NameLabel
@onready var _bit_count_label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/BitCountLabel
@onready var _version_label = $Panel/MarginContainer/VBoxContainer/VersionPanel/VersionLabel
@onready var _length_label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/LengthLabel
@onready var _bpm_label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/BPMLabel
@onready var _difficulty_label = $Panel/MarginContainer/VBoxContainer/DifficultyPanel/DifficultyLabel
@onready var _speed_label = $Panel/MarginContainer/VBoxContainer/SpeedPanel/SpeedLabel
@onready var _damage_label = $Panel/MarginContainer/VBoxContainer/DamagePanel/DamageLabel
@onready var _play_button = $Panel/MarginContainer/VBoxContainer/PlayButton

@onready var _popup_panel = $PopupPanel
@onready var _popup_label = $PopupPanel/MarginContainer/RichTextLabel

@onready var _hover_button_sound = $HoverButton

## This level has been selected to play.
signal button_pressed(level_info: LevelInfo)
signal button_focused

## How many seconds it takes a popup to appear after a level attribute started 
## being hovered over.
const _TIME_TO_SHOW_POPUP = 1

## Level info for this button.
var level_info: LevelInfo

## Start a short timer to wait for a popup to start.
var _popup_timer_on := false
var _popup_time: float = 0

## Cycle through the theme colors each time a new level button is made.
static var current_color_index: int = 0


## Setup the level button with all level details. Call this after instantiation 
## of the scene but before adding as a child to the current scene tree.
func setup(level_information: LevelInfo) -> void:
	level_info = level_information


## Fills all label text with level info.
func _ready() -> void:
	_name_label.text = level_info.song_name
	_version_label.text = level_info.version
	_bit_count_label.text = str(level_info.bit_count) + " bits"
	_length_label.text = _float_as_time(level_info.length)
	_bpm_label.text = _trim_decimals(level_info.bpm) + " BPM"
	_difficulty_label.text = "Difficulty: " + _trim_decimals(level_info.difficulty)
	_speed_label.text = "Speed: " + _trim_decimals(level_info.speed)
	_damage_label.text = "Damage: " + str(level_info.damage)
	
	# Aesthetics
	# Chose a random color from the colors selected for 0, 1, and enter bits.
	var theme_colors = GameSettings.get_theme_colors()
	_name_label.modulate = theme_colors[current_color_index % theme_colors.size()]
	
	current_color_index += 1
	
	_set_play_button_text_color()


## Set popup positions and time when it should show.
func _process(delta: float) -> void:
	if _popup_timer_on and !_popup_panel.visible:
		_popup_time += delta
		if _popup_time > _TIME_TO_SHOW_POPUP:
			_popup_panel.show()
	
	if _popup_panel.visible:
		_popup_panel.global_position.x = get_global_mouse_position().x + 25
		_popup_panel.global_position.y = get_global_mouse_position().y + 25


## Update the title color as the theme colors may have been changed.
func update_button_colors() -> void:
	var theme_colors = GameSettings.get_theme_colors()
	_name_label.modulate = theme_colors[current_color_index % theme_colors.size()]
	
	current_color_index += 1


## Converts the level length in seconds to a string in minutes and seconds.
func _float_as_time(level_length: float) -> String:
	var total_seconds = round(level_length)
	var minutes: int = floor(level_length / 60.0)
	var seconds: int = total_seconds - (minutes * 60)
	
	var string = ""
	if minutes > 0:
		string = str(minutes) + "m "
	
	if seconds > 0:
		string +=str(seconds) + "s"
	
	return string


## If the float has decimal places, it rounds to 2 places. Otherwise, it 
## includes no decimal places and treats it like an int.
func _trim_decimals(value: float) -> String:
	if fmod(value, 1.0) == 0.0: # The float is really just an int.
		return str(int(value))
	else:
		return str(snappedf(value, 0.01))


func _on_play_button_pressed() -> void:
	current_color_index = 0 # Resets the theme coloring cycle.
	button_pressed.emit(level_info)


func _on_play_button_mouse_entered() -> void:
	_set_play_button_text_color()
	
	button_focused.emit()


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
	_hover_button_sound.play()
	_button_panel.scale = Vector2(1.03, 1.03)
	_button_panel.rotation_degrees = randf_range(-1, 1)


## Return the button to its default size and rotation.
func _on_mouse_exited() -> void:
	_button_panel.scale = Vector2(1, 1)
	_button_panel.rotation = 0


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
get a perfect, good, or okay score, or miss a bit. 
The minimum difficulty is 0 and the maximum is 12."
	+ "[color=" + GameSettings.perfect_click_colour + "]"
	+ "\n\nPerfect score: +-" + 
	str(int(PerformanceCalculator.get_perfect_click_range(level_info.difficulty)))
	+ " ms[/color]"
	+ "[color=" + GameSettings.good_click_colour + "]"
	+ "\nGood score: +-" + 
	str(int(PerformanceCalculator.get_good_click_range(level_info.difficulty)))
	+ " ms[/color]"
	+ "[color=" + GameSettings.okay_click_colour + "]"
	+ "\nOkay score: +-" + 
	str(int(PerformanceCalculator.get_okay_click_range(level_info.difficulty)))
	+ " ms[/color]"
	+ "[color=" + GameSettings.missed_click_colour + "]"
	+ "\nMiss: >" + 
	str(int(PerformanceCalculator.get_okay_click_range(level_info.difficulty)))
	+ " ms"
	)
	
	_popup_panel.size = Vector2.ZERO # This forces the panel to resize.
	_start_popup_timer()


func _on_speed_panel_mouse_entered() -> void:
	_popup_label.text = (
"Speed determines how long the bit takes to reach the
cursor after appearing on screen. The minimum speed is
1 and the maximum is 12.\n\n"
	+ "[color=" + GameSettings.perfect_click_colour + "]Bit time to cursor: " +
	str(int(PerformanceCalculator.get_approach_time(level_info.speed) * 1000)) 
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
	+ str(level_info.damage) + "% of total health"
	)
	
	_popup_panel.size = Vector2.ZERO # This forces the panel to resize.
	_start_popup_timer()


func _on_difficulty_panel_mouse_exited() -> void:
	_hide_popup()


func _on_speed_panel_mouse_exited() -> void:
	_hide_popup()


func _on_damage_panel_mouse_exited() -> void:
	_hide_popup()
