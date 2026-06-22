extends Control
## UI for theme settings.

@onready var _zero_bit_color_selector = $MarginContainer/VBoxContainer/HBoxContainer/ZeroBitColor
@onready var _one_bit_color_selector = $MarginContainer/VBoxContainer/HBoxContainer2/OneBitColor
@onready var _enter_bit_color_selector = $MarginContainer/VBoxContainer/HBoxContainer3/EnterBitColor
@onready var _back_bit_color_selector = $MarginContainer/VBoxContainer/HBoxContainer4/BackBitColor

@onready var _menu_click_sound: AudioStreamPlayer = $"../../../../MenuClick"
@onready var _menu_focus_sound: AudioStreamPlayer = $"../../../../MenuFocus"
@onready var _color_click_sound: AudioStreamPlayer = $"../../../../ColorClick"


## Set all theme settings to their current states.
func _ready() -> void:
	_zero_bit_color_selector.set_color(GameSettings.zero_bit_colour)
	_one_bit_color_selector.set_color(GameSettings.one_bit_colour)
	_enter_bit_color_selector.set_color(GameSettings.enter_bit_colour)
	_back_bit_color_selector.set_color(GameSettings.back_bit_colour)


func _on_zero_bit_color_color_changed(color: Color) -> void:
	_color_click_sound.play()
	GameSettings.zero_bit_colour = color


func _on_one_bit_color_color_changed(color: Color) -> void:
	_color_click_sound.play()
	GameSettings.one_bit_colour = color


func _on_enter_bit_color_color_changed(color: Color) -> void:
	_color_click_sound.play()
	GameSettings.enter_bit_colour = color


func _on_back_bit_color_color_changed(color: Color) -> void:
	_color_click_sound.play()
	GameSettings.back_bit_colour = color


func _on_zero_bit_color_pressed() -> void:
	_menu_click_sound.play()


func _on_one_bit_color_pressed() -> void:
	_menu_click_sound.play()


func _on_enter_bit_color_pressed() -> void:
	_menu_click_sound.play()


func _on_back_bit_color_pressed() -> void:
	_menu_click_sound.play()


func _on_zero_bit_color_mouse_entered() -> void:
	_menu_focus_sound.play()


func _on_one_bit_color_mouse_entered() -> void:
	_menu_focus_sound.play()


func _on_enter_bit_color_mouse_entered() -> void:
	_menu_focus_sound.play()


func _on_back_bit_color_mouse_entered() -> void:
	_menu_focus_sound.play()
