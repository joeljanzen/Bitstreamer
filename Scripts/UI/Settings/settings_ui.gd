class_name SettingsUI
extends Control
## Allows the player to change settings while paused or in the main menu.

@onready var _tab_container = $CanvasLayer/MarginContainer/TabContainer

@onready var _menu_focus_sound: AudioStreamPlayer = $MenuFocus
@onready var _menu_click_sound: AudioStreamPlayer = $MenuClick

## Emitted when the close button is pressed, or esc is pressed.
signal settings_closed

const exit_tab_index = 5

static var _last_settings_tab: int = 0

## Set the tab to whatever it last was on load.
func _ready() -> void:
	_tab_container.current_tab = _last_settings_tab


## Input handling.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_close_dialog"):
		accept_event()
		_close_settings()


## A tab was clicked.
func _on_tab_container_tab_clicked(_tab: int) -> void:
	_menu_click_sound.play()
	await _menu_click_sound.finished


func _on_tab_container_tab_hovered(_tab: int) -> void:
	_menu_focus_sound.play()


## Closes the settings tab (also saves the last tab the user was in).
func _close_settings() -> void:
	GameSettings.save_settings()
	_last_settings_tab = _tab_container.current_tab
	settings_closed.emit()
	queue_free()


func _on_back_button_mouse_entered() -> void:
	_menu_focus_sound.play()
