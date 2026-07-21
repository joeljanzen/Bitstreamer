extends Control
## UI for controls settings.

@onready var _zero_bit_button = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/KeybindButton/ZeroBitClick
@onready var _one_bit_button = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/KeybindButton2/OneBitClick
@onready var _enter_bit_button = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/KeybindButton3/EnterBitClick
@onready var _back_bit_button = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/KeybindButton4/BackBitClick
@onready var _pause_resume_button = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/KeybindButton6/PauseResume
@onready var _level_ui_button = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/KeybindButton5/ToggleLevelUI

@onready var _menu_click_sound: AudioStreamPlayer = $"../../../../MenuClick"

const BINDABLE_ACTIONS: Array[String] = [
	"0_bit",
	"1_bit",
	"enter_bit",
	"back_bit",
	"pause",
	"toggle_level_UI",
]

var current_action: String
var current_button: Button
var waiting_for_input := false


## Set all controls settings to their current states.
func _ready() -> void:
	_set_button_text_to_bind(_zero_bit_button, "0_bit")
	_set_button_text_to_bind(_one_bit_button, "1_bit")
	_set_button_text_to_bind(_enter_bit_button, "enter_bit")
	_set_button_text_to_bind(_back_bit_button, "back_bit")
	_set_button_text_to_bind(_pause_resume_button, "pause")


func _input(event: InputEvent) -> void:
	if waiting_for_input:
		if event is InputEventKey || event is InputEventMouseButton and event.is_pressed():
			_menu_click_sound.play()
			accept_event() # Makes sure that clicking enter does not click the button again after.
			
			var same_control_selected := false
			var control_in_use := false
			# Check for overlapping controls, unless the key pressed is already what the
			# action is set to (then we just set it again).
			var current_action_events = InputMap.action_get_events(current_action)
			for e in current_action_events:
				if event.is_match(e):
					same_control_selected = true
			
			if !same_control_selected:
				for i in range(BINDABLE_ACTIONS.size()):
					var input_events: Array[InputEvent] = InputMap.action_get_events(BINDABLE_ACTIONS[i])
					
					for j in range(input_events.size()):
						var event_to_compare = input_events[j]
						if event_to_compare.is_match(event):
							control_in_use = true
							break
			
			if control_in_use:
				current_button.text = " Keybind in use, give another "
			else:
				waiting_for_input = false
				
				if !same_control_selected:
					InputMap.action_erase_events(current_action)
					InputMap.action_add_event(current_action, event)
				
				_set_button_text_to_bind(current_button, current_action)


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


func _on_pause_resume_pressed() -> void:
	_menu_click_sound.play()
	waiting_for_input = true
	current_action = "pause"
	current_button = _pause_resume_button
	current_button.text = " Press any key "
