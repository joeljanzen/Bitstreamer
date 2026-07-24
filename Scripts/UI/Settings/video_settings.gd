extends Control
## UI for video settings.

@onready var _bloom_slider = $"../Video/MarginContainer/VBoxContainer/HBoxContainer/BloomLevel"
@onready var _crt_filter_toggle = $MarginContainer/VBoxContainer/HBoxContainer2/CRTFilter

@onready var _bloom_label = $MarginContainer/VBoxContainer/HBoxContainer/Label2

@onready var _menu_click_sound: AudioStreamPlayer = $"../../../../MenuClick"


## Set all video settings to their current states.
func setup() -> void:
	_bloom_slider.value = GameSettings.bloom_strength
	_crt_filter_toggle.set_pressed_no_signal(GameSettings.crt_filter)


func _ready() -> void:
	setup()


func _on_bloom_level_value_changed(value: float) -> void:
	_menu_click_sound.play()
	GameSettings.bloom_strength = value
	
	@warning_ignore("narrowing_conversion")
	var amount: int = value * 2
	_bloom_label.text = " " +  str(amount)


func _on_crt_filter_toggled(toggled_on: bool) -> void:
	_menu_click_sound.play()
	GameSettings.set_crt_filter(toggled_on)
