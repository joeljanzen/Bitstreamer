extends Control
## UI for controls settings.

@onready var _zero_bit_button = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/KeybindButton/ZeroBitClick
@onready var _one_bit_button = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/KeybindButton2/OneBitClick
@onready var _enter_bit_button = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/KeybindButton3/EnterBitClick
@onready var _back_bit_button = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/KeybindButton4/BackBitClick
@onready var _level_ui_button = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/KeybindButton5/ToggleLevelUI

@onready var _menu_click_sound: AudioStreamPlayer = $"../../../../MenuClick"
@onready var _menu_focus_sound: AudioStreamPlayer = $"../../../../MenuFocus"

var current_action: String
var current_button: Button
var waiting_for_input := false


## Set all controls settings to their current states.
func _ready() -> void:
	_set_button_text_to_bind(_zero_bit_button, "0_bit")
	_set_button_text_to_bind(_one_bit_button, "1_bit")
	_set_button_text_to_bind(_enter_bit_button, "enter_bit")
	_set_button_text_to_bind(_back_bit_button, "back_bit")
	_set_button_text_to_bind(_level_ui_button, "toggle_level_UI")


func _input(event: InputEvent) -> void:
	if waiting_for_input:
		if event is InputEventKey || event is InputEventMouseButton and event.is_pressed():
			_menu_click_sound.play()
			#print("adding keybind of %s to action %s" % [event.as_text(), current_action])
			InputMap.action_erase_events(current_action)
			InputMap.action_add_event(current_action, event)
			_set_button_text_to_bind(current_button, current_action)
			
			waiting_for_input = false


## Set the displayed text for the button to the bind for the event given
func _set_button_text_to_bind(button: Button, event: String) -> void:
	var bind = InputMap.action_get_events(event)[0].as_text().trim_suffix(" - Physical")
	button.text = " " + bind + " "


func _on_zero_bit_click_pressed() -> void:
	_menu_click_sound.play()
	waiting_for_input = true
	current_action = "0_bit"
	current_button = _zero_bit_button
	
	current_button.text = " Press any key "


func _on_one_bit_click_pressed() -> void:
	_menu_click_sound.play()
	waiting_for_input = true
	current_action = "1_bit"
	current_button = _one_bit_button
	
	current_button.text = " Press any key "


func _on_enter_bit_click_pressed() -> void:
	_menu_click_sound.play()
	waiting_for_input = true
	current_action = "enter_bit"
	current_button = _enter_bit_button
	
	current_button.text = " Press any key "


func _on_back_bit_click_pressed() -> void:
	_menu_click_sound.play()
	waiting_for_input = true
	current_action = "back_bit"
	current_button = _back_bit_button
	
	current_button.text = " Press any key "


func _on_toggle_level_ui_pressed() -> void:
	_menu_click_sound.play()
	waiting_for_input = true
	current_action = "toggle_level_UI"
	current_button = _level_ui_button
	
	current_button.text = " Press any key "


func _on_zero_bit_click_mouse_entered() -> void:
	_menu_focus_sound.play()


func _on_one_bit_click_mouse_entered() -> void:
	_menu_focus_sound.play()


func _on_enter_bit_click_mouse_entered() -> void:
	_menu_focus_sound.play()


func _on_back_bit_click_mouse_entered() -> void:
	_menu_focus_sound.play()

func _on_toggle_level_ui_mouse_entered() -> void:
	_menu_focus_sound.play()
