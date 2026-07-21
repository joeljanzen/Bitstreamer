class_name GameCrashUI
extends Control
## Displays when the player loses (the program crashes).

@onready var _accuracy_label: RichTextLabel = $CanvasLayer/MarginContainer2/VBoxContainer/Accuracy
@onready var _progress_label: RichTextLabel = $CanvasLayer/MarginContainer2/VBoxContainer/Progress
@onready var _score_label: RichTextLabel = $CanvasLayer/MarginContainer2/VBoxContainer/Score
@onready var _clicks_label: RichTextLabel = $CanvasLayer/MarginContainer/Clicks
# Sounds.
@onready var _menu_focus_sound: AudioStreamPlayer = $MenuFocus
@onready var _menu_click_sound: AudioStreamPlayer = $MenuClick

## Contains statistics for the current play.
var statistics: GameplayStatistics


## Display statistics for the play.
func _ready() -> void:
	_score_label.text = "Score: %d" % statistics.score
	_accuracy_label.text = "Accuracy: %.2f%%" % statistics.accuracy
	_progress_label.text = "Progress: %.2f%%" % statistics.get_current_progress()
	_clicks_label.text = """perfect: %d
	good: %d
	okay: %d
	miss: %d
	error: %d
	""" % [statistics.perfect_clicks, statistics.good_clicks, 
			statistics.okay_clicks, statistics.missed_clicks, 
			statistics.error_clicks]


## Idle animations in this screen, idk.
func _process(_delta: float) -> void:
	pass


## Connects the statistics for the current play to the GameCrashUI.
func connect_gameplay_stats(stats: GameplayStatistics) -> void:
	statistics = stats


## The player has pressed the reboot button. Clearly.
func _on_reboot_pressed() -> void:
	_menu_click_sound.play()
	await _menu_click_sound.finished
	GameLevel.restart(get_tree())


## Return to the main menu.
func _on_quit_pressed() -> void:
	_menu_click_sound.play()
	await _menu_click_sound.finished
	GameLevel.quit(get_tree())


func _on_reboot_mouse_entered() -> void:
	_menu_focus_sound.play()


func _on_quit_mouse_entered() -> void:
	_menu_focus_sound.play()
