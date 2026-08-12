class_name GameWinUI
extends Control
## Displays when the player loses (the program crashes).


@onready var _accuracy_label: RichTextLabel = $CanvasLayer/MarginContainer2/VBoxContainer/MainStatsPanel/MarginContainer/HBoxContainer/Accuracy
@onready var _combo_label: RichTextLabel = $CanvasLayer/MarginContainer2/VBoxContainer/MainStatsPanel/MarginContainer/HBoxContainer/Combo
@onready var _score_label: RichTextLabel = $CanvasLayer/MarginContainer2/VBoxContainer/ScorePanel/MarginContainer/Score
@onready var _extra_stats_container = $CanvasLayer/MarginContainer2/VBoxContainer/ExtraStatsPanel/MarginContainer/ExtraStats

@onready var _win_message = $CanvasLayer/MarginContainer2/VBoxContainer/WinMsg

# Sounds.
@onready var _menu_focus_sound: AudioStreamPlayer = $MenuFocus
@onready var _menu_click_sound: AudioStreamPlayer = $MenuClick

## Stores data for the current play of a level, including score, combo, etc.
var _play_data: PlayData


## Display statistics for the play.
func _ready() -> void:
	# If the level was completed in practice mode, change the message.
	if GameLevel.last_offset > 0:
		_win_message.text = "Practice Completed!"
	
	# When a play is perfect, make score color perfect.
	if _play_data.accuracy == 100:
		_score_label.modulate = GameSettings.perfect_click_colour
	_score_label.text = str(_play_data.score)
	
	_accuracy_label.text = "%.2f%% Accuracy" % _play_data.accuracy
	_combo_label.text = "%dx Maximum Combo" % _play_data.max_combo
	
	var stat_label = _extra_stats_container.get_children()
	stat_label[0].text = ("[color=%s]%d Perfect[/color]" % 
	[GameSettings.perfect_click_colour, _play_data.perfect_clicks])
	stat_label[1].text = ("[color=%s]%d Good[/color]" % 
	[GameSettings.good_click_colour, _play_data.good_clicks])
	stat_label[2].text = ("[color=%s]%d Okay[/color]" % 
	[GameSettings.okay_click_colour, _play_data.okay_clicks])
	stat_label[3].text = ("[color=%s]%d Miss[/color]" % 
	[GameSettings.missed_click_colour, _play_data.missed_clicks])
	stat_label[4].text = ("[color=%s]%d Error[/color]" % 
	[GameSettings.incorrect_click_colour, _play_data.error_clicks])


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
