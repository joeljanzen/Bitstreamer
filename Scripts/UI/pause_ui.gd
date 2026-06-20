class_name PauseUI
extends Control
## Pause the current game, letting the player quit, change settings, or resume.

@onready var _menu_focus_sound: AudioStreamPlayer = $MenuFocus
@onready var _menu_click_sound: AudioStreamPlayer = $MenuClick
@onready var _canvas = $CanvasLayer

## Emitted when the resume button is pressed.
signal resumed

var _settings_screen = preload("res://Scenes/settings_ui.tscn")

var settings_open := false


## Input handling.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_close_dialog"):
		accept_event()
		resumed.emit()


## The player has pressed the resume button.
func _on_resume_pressed() -> void:
	_menu_click_sound.play()
	await _menu_click_sound.finished
	resumed.emit()


## The player has pressed the settings button.
func _on_settings_pressed() -> void:
	settings_open = true
	_menu_click_sound.play()
	
	var settings: SettingsUI = _settings_screen.instantiate()
	settings.settings_closed.connect(_settings_left)
	_canvas.hide()
	add_child(settings)


## The player has left settings.
func _settings_left() -> void:
	settings_open = false
	_canvas.show()


## The player has pressed the quit button.
func _on_quit_pressed() -> void:
	get_tree().quit(0)


## The player has pressed the reboot button. Clearly.
func _on_reboot_pressed() -> void:
	_menu_click_sound.play()
	await _menu_click_sound.finished
	get_tree().reload_current_scene()


func _on_resume_mouse_entered() -> void:
	_menu_focus_sound.play()


func _on_reboot_mouse_entered() -> void:
	_menu_focus_sound.play()


func _on_settings_mouse_entered() -> void:
	_menu_focus_sound.play()


func _on_quit_mouse_entered() -> void:
	_menu_focus_sound.play()
