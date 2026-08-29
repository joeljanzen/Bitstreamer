class_name GameWinUI
extends Control
## Displays when the player loses (the program crashes).


@onready var _accuracy_label: RichTextLabel = $CanvasLayer/MarginContainer2/VBoxContainer/MainStatsPanel/MarginContainer/HBoxContainer/Accuracy
@onready var _combo_label: RichTextLabel = $CanvasLayer/MarginContainer2/VBoxContainer/MainStatsPanel/MarginContainer/HBoxContainer/Combo
@onready var _score_label: RichTextLabel = $CanvasLayer/MarginContainer2/VBoxContainer/ScorePanel/MarginContainer/Score
@onready var _extra_stats_container = $CanvasLayer/MarginContainer2/VBoxContainer/ExtraStatsPanel/MarginContainer/ExtraStats
@onready var _mods_container = $CanvasLayer/MarginContainer2/VBoxContainer/ModsContainer
@onready var _win_message = $CanvasLayer/MarginContainer2/VBoxContainer/WinMsg

@onready var _arrow_transition: ArrowTransition = $CanvasLayer/ArrowTransition

## The size of mod icons.
const MOD_ICON_SIZE: int = 100

## How many seconds it should take for the score to reach its final value.
const SCORE_ANIMATION_TIME: float = 1.5

## A value between 0 and 1. Closer to 0 means more easing to the final value.
const SCORE_ANIMATION_EASE: float = 0.21

## Stores data for the current play of a level, including score, combo, etc.
var _play_data: PlayData

## The conductor controlling the music. Used to fade it out and do whatever else.
var _conductor: Conductor

## True after the score counting up animation has finished.
var _score_animation_complete := false
## Tracks the weight to lerp between 0 and the actual score.
var _score_animation_weight: float = 0


## Display statistics for the play.
func _ready() -> void:
	# If the level was completed in practice mode, change the message.
	if GameLevel.last_offset > 0:
		_win_message.text = "Practice Completed!"
	
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
	
	if ModManager.has_active_mods():
		_mods_container.show()
		_add_mod_icons()
	
	_arrow_transition.prep_for_fade_out()


## For each active mod, display its icon on the crash screen.
func _add_mod_icons() -> void:
	var icons: Array[Texture2D] = ModManager.get_active_mod_icons()
	
	# Add current active icons as TextureRect nodes.
	for icon in icons:
		var texture_rect = TextureRect.new()
		texture_rect.texture = icon
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		texture_rect.custom_minimum_size.x = MOD_ICON_SIZE
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_mods_container.add_child(texture_rect)


## Score counting up animation.
func _process(delta: float) -> void:
	if _score_animation_weight < 1:
		var curr_weight: float = _score_animation_weight + (delta / SCORE_ANIMATION_TIME)
		_score_animation_weight = min(1, curr_weight)
		# Smooth out animation with easing.
		var final_weight = ease(_score_animation_weight, SCORE_ANIMATION_EASE)
		var score_value: int = lerp(0, _play_data.score, final_weight)
		_score_label.text = str(score_value)
	# When a play is perfect, make score color perfect.
	elif !_score_animation_complete:
		# Can play a cool sound here idk.
		#_menu_click_sound.play()
		if _play_data.accuracy == 100:
			_score_label.modulate = GameSettings.perfect_click_colour
		_score_animation_complete = true


## Connects the data for the current play to the GameWinUI.
func connect_play_data(data: PlayData) -> void:
	_play_data = data


## Connects the conductor to the GameWinUI.
func connect_conductor(conductor: Conductor) -> void:
	_conductor = conductor


## The player has pressed the play again button. Clearly.
func _on_play_again_pressed() -> void:
	SoundManager.play_menu_click()
	
	_conductor.fade_out(ArrowTransition.TRANSITION_FADE_SPEED)
	_arrow_transition.fade_out()
	await _arrow_transition.animation_finished
	
	GameLevel.restart(get_tree())


## Return to the main menu.
func _on_quit_pressed() -> void:
	SoundManager.play_menu_click()
	
	_conductor.fade_out(ArrowTransition.TRANSITION_FADE_SPEED)
	_arrow_transition.fade_out()
	await _arrow_transition.animation_finished
	
	GameLevel.quit(get_tree())


func _on_button_hovered() -> void:
	SoundManager.play_menu_focus()
