class_name PauseUI
extends Control
## Pause the current game, letting the player quit, change settings, or resume.

## Emitted when the resume button is pressed.
signal resumed


## Idle animations in this screen, idk.
func _process(_delta: float) -> void:
	pass


## The player has pressed the resume button.
func _on_resume_pressed() -> void:
	resumed.emit()


## The player has pressed the settings button.
func _on_settings_pressed() -> void:
	pass # Instantiate settings scene here!


## The player has pressed the quit button.
func _on_quit_pressed() -> void:
	get_tree().quit(0)


## The player has pressed the reboot button. Clearly.
func _on_reboot_pressed() -> void:
	get_tree().reload_current_scene()
