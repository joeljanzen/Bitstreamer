extends Control

@onready var _level_button_container = $HBoxContainer/ScrollContainer/MarginContainer/LevelButtonContainer

@onready var _menu_focus_sound: AudioStreamPlayer = $MenuFocus
@onready var _menu_click_sound: AudioStreamPlayer = $MenuClick

var _level_scene = preload("res://Scenes/level.tscn")
var _level_button_scene = preload("res://Scenes/UI/level_button.tscn")

## An array of all level info
var _levels: Array[LevelInfo]


## Load all levels and create buttons for them.
func _ready() -> void:
	# Load all level info
	var level_filenames: PackedStringArray = DirAccess.get_files_at("res://Levels")
	
	for file in level_filenames:
		_levels.push_back(LevelInfo.new(file))
	
	# Make level buttons
	for level in _levels:
		if level.is_valid():
			var level_button: LevelButton = _level_button_scene.instantiate()
			level_button.setup(level)
			level_button.connect("button_pressed", _level_button_pressed)
			level_button.connect("button_focused", _level_button_focused)
			_level_button_container.add_child(level_button)


## Start the level that has been selected.
func _level_button_pressed(level_info: LevelInfo) -> void:
	_menu_click_sound.play()
	await _menu_click_sound.finished
	
	var level_scene: GameLevel = _level_scene.instantiate()
	level_scene.set_level(level_info.file_name)
	get_tree().change_scene_to_node(level_scene)


func _level_button_focused() -> void:
	_menu_focus_sound.play()
