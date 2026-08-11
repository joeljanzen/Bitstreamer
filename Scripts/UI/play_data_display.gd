class_name PlayDataDisplay
extends Control
## Displays the values of a PlayData resource in a panel.

@onready var panel = $Panel
@onready var score_label = $Panel/MarginContainer/VBoxContainer/MainStats/ScoreLabel
@onready var accuracy_label = $Panel/MarginContainer/VBoxContainer/MainStats/VBoxContainer/AccuracyLabel
@onready var max_combo_label = $Panel/MarginContainer/VBoxContainer/MainStats/VBoxContainer/MaxComboLabel
@onready var perfects_label = $Panel/MarginContainer/VBoxContainer/ExtraStats/PerfectsLabel
@onready var goods_label = $Panel/MarginContainer/VBoxContainer/ExtraStats/GoodsLabel
@onready var okays_label = $Panel/MarginContainer/VBoxContainer/ExtraStats/OkaysLabel
@onready var misses_label = $Panel/MarginContainer/VBoxContainer/ExtraStats2/MissesLabel
@onready var errors_label = $Panel/MarginContainer/VBoxContainer/ExtraStats2/ErrorsLabel

@onready var extra_stats = $Panel/MarginContainer/VBoxContainer/ExtraStats
@onready var extra_stats_2 = $Panel/MarginContainer/VBoxContainer/ExtraStats2
@onready var see_more_button = $SeeMoreButton

@onready var _menu_click_sound: AudioStreamPlayer = $MenuClick

## How much to darken the pinkified panel displayed for perfect scores.
const PANEL_DARKEN_AMOUNT: float = 0.70

const MINIMUM_SIZE_DEFAULT = 50

const MINIMUM_SIZE_EXPANDED = 100

## The theme color to use for this PlayDataDisplay's score color.
## Alternates between true and false each time one is created.
static var use_primary := true

var play_data: PlayData

var see_more := false


## Setup the play data display. Call this after instantiation of the scene but 
## before adding as a child to the current scene tree.
func setup(data: PlayData) -> void:
	play_data = data


## Dynamic stylebox colouring.
## Set all label values.
func _ready() -> void:
	score_label.text = str(play_data.score)
	
	# Dynamic colouring stuff.
	if play_data.accuracy == 100:
		score_label.modulate = GameSettings.perfect_click_colour
		
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(GameSettings.perfect_click_colour).darkened(PANEL_DARKEN_AMOUNT)
		panel.add_theme_stylebox_override("panel", style_box)
	else:
		if use_primary:
			score_label.modulate = GameSettings.zero_bit_colour
		else:
			score_label.modulate = GameSettings.one_bit_colour
		use_primary = !use_primary
	
	accuracy_label.text = "%.2f%% Accuracy" % play_data.accuracy
	max_combo_label.text = "%dx Max Combo" % play_data.max_combo
	
	perfects_label.text = ("[color=%s]%d Perfect[/color]" % 
	[GameSettings.perfect_click_colour, play_data.perfect_clicks])
	goods_label.text = ("[color=%s]%d Good[/color]" % 
	[GameSettings.good_click_colour, play_data.good_clicks])
	okays_label.text = ("[color=%s]%d Okay[/color]" % 
	[GameSettings.okay_click_colour, play_data.okay_clicks])
	misses_label.text = ("[color=%s]%d Miss[/color]" % 
	[GameSettings.missed_click_colour, play_data.missed_clicks])
	errors_label.text = ("[color=%s]%d Error[/color]" % 
	[GameSettings.incorrect_click_colour, play_data.error_clicks])


## Show all stats for the play, or hide those extra stats.
func _on_see_more_pressed() -> void:
	_menu_click_sound.play()
	
	see_more = !see_more # Toggle value.
	if see_more:
		custom_minimum_size.y = MINIMUM_SIZE_EXPANDED
		extra_stats.show()
		extra_stats_2.show()
	else:
		custom_minimum_size.y = MINIMUM_SIZE_DEFAULT
		extra_stats.hide()
		extra_stats_2.hide()
