class_name PauseUI
extends Control
## Pause the current game, letting the player quit, change settings, or resume.

@onready var _progress_label = $CanvasLayer/VBoxContainer/Progress

@onready var _menu_focus_sound: AudioStreamPlayer = $MenuFocus
@onready var _menu_click_sound: AudioStreamPlayer = $MenuClick
@onready var _canvas = $CanvasLayer

## Emitted when the resume button is pressed.
signal resumed

var _settings_scene = preload("res://Scenes/UI/settings_ui.tscn")

## Contains statistics for the current play.
var statistics: GameplayStatistics


## Set progress amount.
func _ready() -> void:
	var progress = statistics.get_current_progress()
	if progress > 0:
		_progress_label.text = "Current Progress: %.2f%%" % progress
	else: # progress is not applicable for whatever reason.
		_progress_label.hide()


## Input handling.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		accept_event()
		resumed.emit()


## Connects the statistics for the current play to the PauseUI.
func connect_gameplay_stats(stats: GameplayStatistics) -> void:
	statistics = stats


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
	_menu_click_sound.play() # For the button they pressed to leave settings.
	_canvas.show()


## Return to the main menu.
func _on_quit_pressed() -> void:
	_menu_click_sound.play()
	await _menu_click_sound.finished
	GameLevel.quit(get_tree())


## The player has pressed the reboot button. Clearly.
func _on_reboot_pressed() -> void:
	_menu_click_sound.play()
	await _menu_click_sound.finished
	GameLevel.restart(get_tree())


func _on_resume_mouse_entered() -> void:
	_menu_focus_sound.play()


func _on_reboot_mouse_entered() -> void:
	_menu_focus_sound.play()


func _on_settings_mouse_entered() -> void:
	_menu_focus_sound.play()


func _on_quit_mouse_entered() -> void:
	_menu_focus_sound.play()
