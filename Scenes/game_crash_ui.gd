class_name GameCrashUI
extends Control
## Displays when the player loses (the program crashes).

@onready var _accuracy_label: RichTextLabel = $CanvasLayer/Accuracy
@onready var _combo_label: RichTextLabel = $CanvasLayer/Combo
@onready var _score_label: RichTextLabel = $CanvasLayer/Score

## Contains statistics for the current level.
var statistics: LevelStatistics


## Display statistics for the play.
func _ready() -> void:
	_score_label.text = "Score: %d" % statistics.score
	_accuracy_label.text = "Accuracy: %.2f%%" % statistics.accuracy
	_combo_label.text = "Maximum combo: %dx" % statistics.max_combo


## Idle animations in this screen, idk.
func _process(_delta: float) -> void:
	pass


## Connects the statistics for the current level to the GameCrashUI.
func connect_stats(stats: LevelStatistics) -> void:
	statistics = stats


## The player has pressed the reboot button. Clearly.
func _on_reboot_pressed() -> void:
	get_tree().reload_current_scene()


## The player has pressed the quit button. Clearly.
func _on_quit_pressed() -> void:
	get_tree().quit(0)
