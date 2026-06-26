extends Control

@onready var _level_button_container = $CanvasLayer/HBoxContainer/ScrollContainer/MarginContainer/LevelButtonContainer
@onready var _back_button = $CanvasLayer/BackButton
@onready var _scroll_box = $CanvasLayer/HBoxContainer/ScrollContainer

@onready var _menu_focus_sound: AudioStreamPlayer = $MenuFocus
@onready var _menu_click_sound: AudioStreamPlayer = $MenuClick

## Emitted when the close button is pressed, or esc is pressed.
signal selection_closed

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
	
	level_info.load_level_bits_and_delays()
	
	if level_info.is_valid():
		var level_scene: GameLevel = load("res://Scenes/level.tscn").instantiate()
		level_scene.set_level(level_info)
		Bit.in_main_menu = false
		LevelInfo.last_played = level_info
		get_tree().change_scene_to_node(level_scene)
	else:
		push_error("Failed to load the level!")


func _level_button_focused() -> void:
	_menu_focus_sound.play()


## Hides the level select UI.
func hide_UI():
	_back_button.hide()
	_level_button_container.hide()
	_scroll_box.mouse_filter = _scroll_box.MOUSE_FILTER_IGNORE


## Shows the level select UI.
func show_UI():
	_back_button.show()
	_level_button_container.show()
	_scroll_box.mouse_filter = _scroll_box.MOUSE_FILTER_STOP
	
	# In the event that the theme colors changed.
	LevelButton.current_color_index = 0
	for button: LevelButton in _level_button_container.get_children():
		button.update_button_colors()


## Returns if the UI is currently visible.
func UI_is_visible() -> bool:
	return _level_button_container.visible


func _on_back_button_pressed() -> void:
	_menu_click_sound.play()
	hide_UI()
	selection_closed.emit()


func _on_back_button_mouse_entered() -> void:
	_menu_focus_sound.play()
