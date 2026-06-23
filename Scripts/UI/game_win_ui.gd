class_name GameWinUI
extends Control
## Displays when the player loses (the program crashes).

@onready var _accuracy_label: RichTextLabel = $CanvasLayer/Accuracy
@onready var _combo_label: RichTextLabel = $CanvasLayer/Combo
@onready var _score_label: RichTextLabel = $CanvasLayer/Score
@onready var _clicks_label: RichTextLabel = $CanvasLayer/Clicks
# Sounds.
@onready var _menu_focus_sound: AudioStreamPlayer = $MenuFocus
@onready var _menu_click_sound: AudioStreamPlayer = $MenuClick

var _main_menu_scene = preload("res://Scenes/UI/main_menu.tscn")

## Contains statistics for the current play.
var statistics: GameplayStatistics


## Display statistics for the play.
func _ready() -> void:
	_score_label.text = "Score: %d" % statistics.score
	_accuracy_label.text = "Accuracy: %.2f%%" % statistics.accuracy
	_combo_label.text = "Maximum combo: %dx" % statistics.max_combo
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


## Connects the statistics for the current play to the GameWinUI.
func connect_gameplay_stats(stats: GameplayStatistics) -> void:
	statistics = stats


## The player has pressed the play again button. Clearly.
func _on_play_again_pressed() -> void:
	_menu_click_sound.play()
	await _menu_click_sound.finished
	get_tree().reload_current_scene()


## Return to the main menu.
func _on_quit_pressed() -> void:
	_menu_click_sound.play()
	await _menu_click_sound.finished
	get_tree().change_scene_to_node(_main_menu_scene.instantiate())


func _on_play_again_mouse_entered() -> void:
	_menu_focus_sound.play()


func _on_quit_mouse_entered() -> void:
	_menu_focus_sound.play()
