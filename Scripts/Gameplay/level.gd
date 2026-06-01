extends Node2D
## A game level, where gameplay occurs and all that jazz.

@onready var _levelUI: LevelStatistics = $LevelUI
@onready var _environment: WorldEnvironment = $WorldEnvironment
@onready var _play_area: Node = $PlayArea

## The strength of blur when the game is paused.
const PAUSE_BLUR_STRENGTH := 0.5

var _crash_screen = preload("res://Scenes/game_crash_ui.tscn")
var _pause_screen = preload("res://Scenes/pause_ui.tscn")
var _pause_instance: PauseUI

## The game is paused.
var paused := false

## True if the UI was visible before pausing.
var _UI_was_visible := true

## The game has been failed.
var failed := false


## Connect to the failed signal.
func _ready() -> void:
	Signals.failed.connect(_failed)
	
	# Aesthetics.
	_environment.environment.glow_bloom = GameSettings.bloom_strength


## Input handling.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if paused:
			resumed()
		elif not failed:
			_paused()
	elif event.is_action_pressed("toggle level UI") and !paused:
		_levelUI.toggle_visible()


## The level has been unpaused.
func resumed() -> void:
	paused = false
	_pause_instance.queue_free()
	if _UI_was_visible:
		_levelUI.toggle_visible()
	_play_area.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Disable background blur.
	_environment.environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	_environment.environment.glow_bloom = GameSettings.bloom_strength


## The level has been failed.
func _failed() -> void:
	failed = true
	_play_area.process_mode = Node.PROCESS_MODE_DISABLED
	
	var crash_screen: GameCrashUI = _crash_screen.instantiate()
	crash_screen.connect_stats(_levelUI)
	add_child(crash_screen)


## The level has been paused.
func _paused() -> void:
	paused = true
	_UI_was_visible = _levelUI.UI_is_visible()
	_levelUI.hide_UI()
	_play_area.process_mode = Node.PROCESS_MODE_DISABLED
	
	_pause_instance = _pause_screen.instantiate()
	_pause_instance.resumed.connect(resumed)
	add_child(_pause_instance)
	
	# Enable background blur.
	_environment.environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_REPLACE
	_environment.environment.glow_bloom = PAUSE_BLUR_STRENGTH
