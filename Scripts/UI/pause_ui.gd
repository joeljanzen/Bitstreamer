class_name PauseUI
extends Control
## Pause the current game, letting the player quit, change settings, or resume.

@onready var _progress_label = $CanvasLayer/VBoxContainer/Progress
# Hide this to hide the whole thing, for the tutorial basically
@onready var _current_play_container = $CanvasLayer/CurrentPlay/CurrentPlayContainer

@onready var _canvas = $CanvasLayer

@onready var _arrow_transition: ArrowTransition = $CanvasLayer/ArrowTransition

## If the play display was expanded last time the player resumed playing.
static var expanded_play_display := true

## Emitted when the resume button is pressed.
signal resumed

var _settings_scene = preload("res://Scenes/UI/settings_ui.tscn")
var _play_display_scene = preload("res://Scenes/UI/play_data_display.tscn")

var _level_UI: LevelUI


## Set progress amount.
func _ready() -> void:
	var progress = _level_UI.get_current_progress()
	if progress > 0:
		_progress_label.text = "Current Progress: %.2f%%" % progress
	else: # progress is not applicable for whatever reason.
		_progress_label.hide()
	
	# Add play display with current playdata.
	var play_display: PlayDataDisplay = _play_display_scene.instantiate()
	play_display.setup(_level_UI.play_data)
	_current_play_container.add_child(play_display)
	
	if expanded_play_display:
		play_display.toggle_see_more()
	
	_arrow_transition.prep_for_fade_out()


## Input handling.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		accept_event()
		resumed.emit()


## Connects the LevelUI to the PauseUI.
func connect_level_UI(UI: LevelUI) -> void:
	_level_UI = UI


## The player has pressed the resume button.
func _on_resume_pressed() -> void:
	resumed.emit()


## The player has pressed the settings button.
func _on_settings_pressed() -> void:
	# The bloom slider actually plays the click sound when it's set to the 
	# current value of bloom so we don't need to play it again lol!
	
	var settings: SettingsUI = _settings_scene.instantiate()
	settings.settings_closed.connect(_settings_closed)
	_canvas.hide()
	add_child(settings)


## The player has left settings.
func _settings_closed() -> void:
	_canvas.show()


## Return to the main menu.
func _on_quit_pressed() -> void:
	SoundManager.play_menu_click()
	_arrow_transition.fade_out()
	SoundManager.play_woosh()
	await _arrow_transition.animation_finished
	
	GameLevel.quit(get_tree())


## The player has pressed the reboot button. Clearly.
func _on_reboot_pressed() -> void:
	SoundManager.play_menu_click()
	_arrow_transition.fade_out()
	SoundManager.play_woosh()
	await _arrow_transition.animation_finished
	
	GameLevel.restart(get_tree())


func _on_button_hovered() -> void:
	SoundManager.play_menu_focus()
