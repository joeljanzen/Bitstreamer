extends Control
## UI for gameplay settings.

@onready var _bit_click_effect_toggle = $MarginContainer/VBoxContainer/HBoxContainer/BitClickEffect
@onready var _ignores_perfect_clicks_toggle = $MarginContainer/VBoxContainer/HBoxContainer2/IgnoresPerfectClicks
@onready var _fade_slider = $MarginContainer/VBoxContainer/HBoxContainer3/FadeTime
@onready var _cursor_flicker_toggle = $MarginContainer/VBoxContainer/HBoxContainer4/CursorFlicker
@onready var _level_ui_toggle = $MarginContainer/VBoxContainer/HBoxContainer5/LevelUI

@onready var _fade_label = $MarginContainer/VBoxContainer/HBoxContainer3/Label2

@onready var _menu_click_sound: AudioStreamPlayer = $"../../../../MenuClick"


## Set all gameplay settings to their current states.
func _ready() -> void:
	_bit_click_effect_toggle.set_pressed_no_signal(GameSettings.bit_click_effect)
	_ignores_perfect_clicks_toggle.set_pressed_no_signal(GameSettings.ignores_perfect_clicks)
	_fade_slider.value = GameSettings.clicked_fade_time
	_cursor_flicker_toggle.set_pressed_no_signal(GameSettings.cursor_flicker)
	_level_ui_toggle.set_pressed_no_signal(GameSettings.level_UI_enabled)


func _on_bit_click_effect_toggled(toggled_on: bool) -> void:
	_menu_click_sound.play()
	GameSettings.bit_click_effect = toggled_on


func _on_ignores_perfect_clicks_toggled(toggled_on: bool) -> void:
	_menu_click_sound.play()
	GameSettings.ignores_perfect_clicks = toggled_on


## Update bit fade time.
func _on_fade_time_value_changed(value: float) -> void:
	GameSettings.clicked_fade_time = value
	
	@warning_ignore("narrowing_conversion")
	var milliseconds: int = value * 1000
	_fade_label.text = (
			" ".repeat(get_millliseconds_padding(milliseconds)) 
			+ str(milliseconds) + " ms"
	)


func _on_fade_time_drag_started() -> void:
	_menu_click_sound.play()


## Get the required padding for a string of a given milliseconds.
func get_millliseconds_padding(milliseconds: int) -> int:
	var front_padding: = 1
	if milliseconds < 1000:
		front_padding += 1
	if milliseconds < 100:
		front_padding += 1
	if milliseconds < 10:
		front_padding += 1
	return front_padding


func _on_cursor_flicker_toggled(toggled_on: bool) -> void:
	_menu_click_sound.play()
	GameSettings.cursor_flicker = toggled_on


func _on_level_ui_toggled(toggled_on: bool) -> void:
	_menu_click_sound.play()
	GameSettings.level_UI_enabled = toggled_on
