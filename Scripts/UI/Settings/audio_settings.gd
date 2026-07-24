extends Control
## UI for audio settings.

@onready var _master_slider = $MarginContainer/VBoxContainer/HBoxContainer1/MasterVolume
@onready var _music_slider =$MarginContainer/VBoxContainer/HBoxContainer2/MusicVolume
@onready var _sound_slider = $MarginContainer/VBoxContainer/HBoxContainer3/SoundVolume

@onready var _master_label = $MarginContainer/VBoxContainer/HBoxContainer1/Label2
@onready var _music_label = $MarginContainer/VBoxContainer/HBoxContainer2/Label2
@onready var _sound_label = $MarginContainer/VBoxContainer/HBoxContainer3/Label2

@onready var _menu_click_sound: AudioStreamPlayer = $"../../../../MenuClick"


## Set sliders to their appropriate positions (where volumes are currently at).
func setup() -> void:
	var volume = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Master"))
	_master_slider.value = volume
	_master_label.text = get_percent_text(volume)
	volume = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Music"))
	_music_slider.value = volume
	_music_label.text = get_percent_text(volume)
	volume = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("SFX"))
	_sound_slider.value = volume
	_sound_label.text = get_percent_text(volume)


func _ready() -> void:
	setup()


func _on_master_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	_master_label.text = get_percent_text(value)


func _on_music_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))
	_music_label.text = get_percent_text(value)


func _on_sound_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))
	_sound_label.text = get_percent_text(value)


## Get the required padding for a string of a given percentage.
func get_padding(percentage: int) -> int:
	var front_padding: = 1
	if percentage < 100:
		front_padding += 1
	if percentage < 10:
		front_padding += 1
	return front_padding


## Return the percentage for the value given as a string with padding.
func get_percent_text(value: float) -> String:
	var percentage: int = round(value * 100)
	return " ".repeat(get_padding(percentage)) + str(percentage)+ "%"


# UI SFX

func _on_master_volume_drag_started() -> void:
	_menu_click_sound.play()


func _on_music_volume_drag_started() -> void:
	_menu_click_sound.play()


func _on_sound_volume_drag_started() -> void:
	_menu_click_sound.play()
