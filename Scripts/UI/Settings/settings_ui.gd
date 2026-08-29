class_name SettingsUI
extends Control
## Allows the player to change settings while paused or in the main menu.

@onready var _tab_container = $CanvasLayer/MarginContainer/TabContainer

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
	SoundManager.play_menu_click()


func _on_tab_container_tab_hovered(_tab: int) -> void:
	SoundManager.play_menu_focus()


## Closes the settings tab (also saves the last tab the user was in).
func _close_settings() -> void:
	SoundManager.play_menu_click()
	GameSettings.save_settings()
	_last_settings_tab = _tab_container.current_tab
	settings_closed.emit()
	queue_free()


func _on_button_hovered() -> void:
	SoundManager.play_menu_focus()


func _on_restore_button_pressed() -> void:
	SoundManager.play_menu_click()
	var tab = _tab_container.current_tab
	GameSettings.load_default_settings(tab)
	# Get this tab to display its new values.
	_tab_container.get_child(tab).setup()
