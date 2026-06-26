class_name LevelButton
extends Control

@onready var _name_label = $CanvasLayer/MarginContainer/Panel/MarginContainer/VBoxContainer/NamePanel/NameLabel
@onready var _length_label = $CanvasLayer/MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/LengthLabel
@onready var _bpm_label = $CanvasLayer/MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/BPMLabel
@onready var _difficulty_label = $CanvasLayer/MarginContainer/Panel/MarginContainer/VBoxContainer/DifficultyPanel/DifficultyLabel
@onready var _speed_label = $CanvasLayer/MarginContainer/Panel/MarginContainer/VBoxContainer/SpeedPanel/SpeedLabel
@onready var _damage_label = $CanvasLayer/MarginContainer/Panel/MarginContainer/VBoxContainer/DamagePanel/DamageLabel

## This level has been selected to play.
signal button_pressed(level_info: LevelInfo)
signal button_focused

## Level info for this button.
var level_info: LevelInfo


## Setup the level button with all level details. Call this after instantiation 
## of the scene but before adding as a child to the current scene tree.
func setup(level_information: LevelInfo) -> void:
	level_info = level_information


## Fills all label text with level info.
func _ready() -> void:
	_name_label.text = level_info.level_name
	_length_label.text = _float_as_time(level_info.length)
	_bpm_label.text = _trim_decimals(level_info.bpm) + " BPM"
	_difficulty_label.text = "Difficulty: " + _trim_decimals(level_info.difficulty)
	_speed_label.text = "Speed: " + _trim_decimals(level_info.speed)
	_damage_label.text = "Damage: " + str(level_info.damage)


## Converts the level length in seconds to a string in minutes and seconds.
func _float_as_time(level_length: float) -> String:
	var total_seconds = round(level_length)
	var minutes: int = floor(level_length / 60.0)
	var seconds: int = total_seconds - (minutes * 60)
	return str(minutes) + "m " + str(seconds) + "s"


## If the float has decimal places, it rounds to 2 places. Otherwise, it 
## includes no decimal places and treats it like an int.
func _trim_decimals(value: float) -> String:
	if fmod(value, 1.0) == 0.0: # The float is really just an int.
		return str(int(value))
	else:
		return str(snappedf(value, 0.01))


func _on_play_button_pressed() -> void:
	button_pressed.emit(level_info)


func _on_play_button_mouse_entered() -> void:
	button_focused.emit()
