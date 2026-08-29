extends Control
## UI for theme settings.

@onready var _zero_bit_color_selector = $MarginContainer/VBoxContainer/HBoxContainer/ZeroBitColor
@onready var _one_bit_color_selector = $MarginContainer/VBoxContainer/HBoxContainer2/OneBitColor
@onready var _enter_bit_color_selector = $MarginContainer/VBoxContainer/HBoxContainer3/EnterBitColor
@onready var _back_bit_color_selector = $MarginContainer/VBoxContainer/HBoxContainer4/BackBitColor


## Set all theme settings to their current states.
func setup() -> void:
	_zero_bit_color_selector.set_color(GameSettings.zero_bit_colour)
	_one_bit_color_selector.set_color(GameSettings.one_bit_colour)
	_enter_bit_color_selector.set_color(GameSettings.enter_bit_colour)
	_back_bit_color_selector.set_color(GameSettings.back_bit_colour)


func _ready() -> void:
	setup()


func _on_zero_bit_color_color_changed(color: Color) -> void:
	SoundManager.play_color_select()
	GameSettings.zero_bit_colour = color


func _on_one_bit_color_color_changed(color: Color) -> void:
	SoundManager.play_color_select()
	GameSettings.one_bit_colour = color


func _on_enter_bit_color_color_changed(color: Color) -> void:
	SoundManager.play_color_select()
	GameSettings.enter_bit_colour = color


func _on_back_bit_color_color_changed(color: Color) -> void:
	SoundManager.play_color_select()
	GameSettings.back_bit_colour = color


func _on_button_pressed() -> void:
	SoundManager.play_menu_click()
