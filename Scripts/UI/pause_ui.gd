class_name PauseUI
extends Control
## Pause the current game, letting the player quit, change settings, or resume.

@onready var _menu_focus_sound: AudioStreamPlayer = $MenuFocus
@onready var _menu_click_sound: AudioStreamPlayer = $MenuClick

## Emitted when the resume button is pressed.
signal resumed


## Idle animations in this screen, idk.
func _process(_delta: float) -> void:
	pass


## The player has pressed the resume button.
func _on_resume_pressed() -> void:
	_menu_click_sound.play()
	await _menu_click_sound.finished
	resumed.emit()


## The player has pressed the settings button.
func _on_settings_pressed() -> void:
	_menu_click_sound.play()
	# Instantiate settings scene here!


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
