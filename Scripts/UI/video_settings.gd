extends Control
## UI for video settings.

@onready var _bloom_slider = $"../Video/MarginContainer/VBoxContainer/HBoxContainer/BloomLevel"
@onready var _bloom_label = $MarginContainer/VBoxContainer/HBoxContainer/Label2

@onready var _menu_click_sound: AudioStreamPlayer = $"../../../../MenuClick"

## Set all video settings to their current states.
func _ready() -> void:
	_bloom_slider.value = GameSettings.bloom_strength


func _on_bloom_level_value_changed(value: float) -> void:
	_menu_click_sound.play()
	GameSettings.bloom_strength = value
	
	@warning_ignore("narrowing_conversion")
	var amount: int = value * 2
	_bloom_label.text = " " +  str(amount)

# UI SFX

func _on_bloom_level_drag_started() -> void:
	_menu_click_sound.play()
