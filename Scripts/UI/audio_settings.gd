extends Control
## UI for audio settings.

@onready var _master_slider = $MarginContainer/VBoxContainer/HBoxContainer1/MasterVolume
@onready var _music_slider =$MarginContainer/VBoxContainer/HBoxContainer2/MusicVolume
@onready var _sound_slider = $MarginContainer/VBoxContainer/HBoxContainer3/SoundVolume
 

## Set sliders to their appropriate positions (where volumes are currently at).
func _ready() -> void:
	_master_slider.value = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Master"))
	_music_slider.value = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Music"))
	_sound_slider.value = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("SFX"))


## Update Master bus volume.
func _on_master_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))


## Update Music bus volume.
func _on_music_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))


## Update SFX bus volume.
func _on_sound_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))
