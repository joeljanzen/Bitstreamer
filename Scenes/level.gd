extends Node2D
## A game level, where gameplay occurs and all that jazz.

@onready var _levelUI: LevelStatistics = $LevelUI
@onready var _play_area: Node = $PlayArea

var _crash_screen = preload("res://Scenes/game_crash_ui.tscn")


## Connect to the failed signal.
func _ready() -> void:
	Signals.failed.connect(failed)


## Start the level
func start() -> void:
	pass


## The level has been failed
func failed() -> void:
	_play_area.process_mode = Node.PROCESS_MODE_DISABLED
	
	var crash_screen: GameCrashUI = _crash_screen.instantiate()
	crash_screen.connect_stats(_levelUI)
	add_child(crash_screen)
