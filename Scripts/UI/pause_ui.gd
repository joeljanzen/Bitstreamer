class_name PauseUI
extends Control
## Pause the current game, letting the player quit, change settings, or resume.

@onready var _menu_focus_sound: AudioStreamPlayer = $MenuFocus
@onready var _menu_click_sound: AudioStreamPlayer = $MenuClick
@onready var _canvas = $CanvasLayer

## Emitted when the resume button is pressed.
signal resumed

var _settings_scene = preload("res://Scenes/UI/settings_ui.tscn")


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
	# The bloom slider actually plays the click sound when it's set to the 
	# current value of bloom so we don't need to play it again lol!
	#_menu_click_sound.play()
	
	var settings: SettingsUI = _settings_scene.instantiate()
	settings.settings_closed.connect(_settings_closed)
	_canvas.hide()
	add_child(settings)


## The player has left settings.
func _settings_closed() -> void:
	_canvas.show()


## Return to the main menu.
func _on_quit_pressed() -> void:
	_menu_click_sound.play()
	await _menu_click_sound.finished
	var menu_scene = load("res://Scenes/UI/main_menu.tscn").instantiate()
	menu_scene.start_in_level_select = true
	get_tree().change_scene_to_node(menu_scene)


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
