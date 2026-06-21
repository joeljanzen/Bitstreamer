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
func _ready() -> void:
	_master_slider.value = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Master"))
	_music_slider.value = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Music"))
	_sound_slider.value = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("SFX"))


## Update Master bus volume.
func _on_master_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	var percentage: int = round(value * 100)
	_master_label.text = " ".repeat(get_padding(percentage)) + str(percentage)+ "%"


## Update Music bus volume.
func _on_music_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))
	var percentage: int = round(value * 100)
	_music_label.text = " ".repeat(get_padding(percentage)) + str(percentage)+ "%"


## Update SFX bus volume.
func _on_sound_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))
	var percentage: int = round(value * 100)
	_sound_label.text = " ".repeat(get_padding(percentage)) + str(percentage)+ "%"


## Get the required padding for a string of a given percentage.
func get_padding(percentage: int) -> int:
	var front_padding: = 1
	if percentage < 100:
		front_padding += 1
	if percentage < 10:
		front_padding += 1
	return front_padding


# UI SFX

func _on_master_volume_drag_started() -> void:
	_menu_click_sound.play()


func _on_music_volume_drag_started() -> void:
	_menu_click_sound.play()


func _on_sound_volume_drag_started() -> void:
	_menu_click_sound.play()
