class_name GameWinUI
extends Control
## Displays when the player loses (the program crashes).

@onready var _accuracy_label: RichTextLabel = $CanvasLayer/MarginContainer2/VBoxContainer/Accuracy
@onready var _combo_label: RichTextLabel = $CanvasLayer/MarginContainer2/VBoxContainer/Combo
@onready var _score_label: RichTextLabel = $CanvasLayer/MarginContainer2/VBoxContainer/Score
@onready var _clicks_label: RichTextLabel = $CanvasLayer/MarginContainer/Clicks
# Sounds.
@onready var _menu_focus_sound: AudioStreamPlayer = $MenuFocus
@onready var _menu_click_sound: AudioStreamPlayer = $MenuClick

## Stores data for the current play of a level, including score, combo, etc.
var _play_data: PlayData


## Display statistics for the play.
func _ready() -> void:
	_score_label.text = "Score: %d" % _play_data.score
	_accuracy_label.text = "Accuracy: %.2f%%" % _play_data.accuracy
	_combo_label.text = "Maximum combo: %dx" % _play_data.max_combo
	_clicks_label.text = """perfect: %d
	good: %d
	okay: %d
	miss: %d
	error: %d
	""" % [_play_data.perfect_clicks, _play_data.good_clicks, 
			_play_data.okay_clicks, _play_data.missed_clicks, 
			_play_data.error_clicks]


## Idle animations in this screen, idk.
func _process(_delta: float) -> void:
	pass


## Connects the data for the current play to the GameWinUI.
func connect_play_data(data: PlayData) -> void:
	_play_data = data


## The player has pressed the play again button. Clearly.
func _on_play_again_pressed() -> void:
	GameLevel.restart(get_tree())


## Return to the main menu.
func _on_quit_pressed() -> void:
	_menu_click_sound.play()
	await _menu_click_sound.finished
	GameLevel.quit(get_tree())


func _on_play_again_mouse_entered() -> void:
	_menu_focus_sound.play()


func _on_quit_mouse_entered() -> void:
	_menu_focus_sound.play()
