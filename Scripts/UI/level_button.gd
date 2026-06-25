class_name LevelButton
extends Control

@onready var _name_label = $CanvasLayer/MarginContainer/Panel/MarginContainer/VBoxContainer/NamePanel/NameLabel
@onready var _length_label = $CanvasLayer/MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/LengthLabel
@onready var _bpm_label = $CanvasLayer/MarginContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/BPMLabel
@onready var _difficulty_label = $CanvasLayer/MarginContainer/Panel/MarginContainer/VBoxContainer/DifficultyPanel/DifficultyLabel
@onready var _speed_label = $CanvasLayer/MarginContainer/Panel/MarginContainer/VBoxContainer/SpeedPanel/SpeedLabel
@onready var _damage_label = $CanvasLayer/MarginContainer/Panel/MarginContainer/VBoxContainer/DamagePanel/DamageLabel

## The level has been selected to play.
signal button_pressed
signal button_focused

## Level info for this button.
var level_info: LevelInfo


## Initialize the level button, given all level details.
func _init(level_information: LevelInfo) -> void:
	level_info = level_information


## Fills all label text with level info.
func _ready() -> void:
	_name_label.text = level_info.level_name
	_length_label.text = _float_as_time(level_info.length)
	_bpm_label.text = str(level_info.bpm) + " BPM"
	_difficulty_label.text = "Difficulty: " + str(level_info.difficulty)
	_speed_label = "Speed: " + str(level_info.speed)
	_damage_label = "Damage: " + str(level_info.damage)


## Converts the level length in seconds to a string in minutes and seconds.
func _float_as_time(level_length: float) -> String:
	var total_seconds = round(level_length)
	var minutes = floor(level_length / 60.0)
	var seconds = total_seconds - (minutes * 60)
	return str(minutes) + "m " + str(seconds) + "s"


func _on_play_button_pressed() -> void:
	button_pressed.emit()


func _on_play_button_mouse_entered() -> void:
	button_focused.emit()
