extends Control

@onready var _level_button_container = $CanvasLayer/HBoxContainer/ScrollContainer/MarginContainer/LevelButtonContainer
@onready var _back_button = $CanvasLayer/BackButton
@onready var _scroll_box = $CanvasLayer/HBoxContainer/ScrollContainer
@onready var _filters_panel = $CanvasLayer/FiltersPanel
@onready var _filters_button_toggle = $CanvasLayer/FiltersButton
@onready var _filter_button_container = $CanvasLayer/FiltersPanel/MarginContainer/FilterButtonContainer

@onready var _menu_focus_sound: AudioStreamPlayer = $MenuFocus
@onready var _menu_click_sound: AudioStreamPlayer = $MenuClick

## All the buttons to choose a filter for level sorting.
var _filter_buttons: Array[Button]

## Emitted when the close button is pressed, or esc is pressed.
signal selection_closed

## The last comparator function used to sort levels.
static var _last_filter_used: Callable = _compare_level_difficulty

## The filter button that is currently selected.
static var _current_filter_index: int = 1

## The last position the player was on the level selection menu (on the 
## scrollbar).
static var _last_level_select_position: int = 0

var _level_button_scene = preload("res://Scenes/UI/level_button.tscn")

## An array of all level info
var _levels: Array[LevelInfo]


## Load all levels and create buttons for them.
func _ready() -> void:
	_scroll_box.set_deferred("scroll_horizontal", _last_level_select_position)
	
	# Add filter button children
	for child in _filter_button_container.get_children():
		if child is Button:
			_filter_buttons.push_back(child)
	
	_filter_buttons[_current_filter_index].disabled = true
	
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
			_level_button_container.add_child(level_button)
	
	_sort_levels_by_comparator(_last_filter_used)


## Rearranges the children of the button container based on the comparator 
## function passed (it should take 2 array elements and return if the first 
## should come before the second).
func _sort_levels_by_comparator(comparator: Callable) -> void:
	_last_filter_used = comparator
	
	var children: Array[Node] = _level_button_container.get_children()
	
	children.sort_custom(comparator)
	
	# Rearrange children appropriately
	for i in range(children.size()):
		_level_button_container.move_child(children[i], i)


## Start the level that has been selected.
func _level_button_pressed(level_info: LevelInfo) -> void:
	_menu_click_sound.play()
	await _menu_click_sound.finished
	
	level_info.load_level_bits_and_delays()
	
	if level_info.is_valid():
		_last_level_select_position = _scroll_box.scroll_horizontal
		
		var level_scene: GameLevel = load("res://Scenes/level.tscn").instantiate()
		Bit.in_main_menu = false
		LevelInfo.last_played = level_info
		
		# Attach tutorial script for the tutorial level.
		if level_info.version == "Tutorial":
			level_scene.set_script(load("res://Scripts/Gameplay/tutorial_level.gd"))
		
		get_tree().change_scene_to_node(level_scene)
	else:
		push_error("Failed to load the level!")


## Hides the level select UI.
func hide_UI():
	_back_button.hide()
	_filters_button_toggle.hide()
	_level_button_container.hide()
	
	_scroll_box.mouse_filter = _scroll_box.MOUSE_FILTER_IGNORE
	_last_level_select_position = _scroll_box.scroll_horizontal
	
	if _filters_panel.visible:
		# Cannot hide right away as that will trigger filter button to 
		# show itself again (through the mouse_exited signal) instead we
		# do it after frame process idk it works ig.
		await get_tree().process_frame
		_filters_panel.hide()


## Shows the level select UI.
func show_UI():
	_back_button.show()
	_filters_button_toggle.show()
	_level_button_container.show()
	_scroll_box.mouse_filter = _scroll_box.MOUSE_FILTER_STOP
	
	# In the event that the theme colors changed.
	LevelButton.current_color_index = 0
	for button: LevelButton in _level_button_container.get_children():
		button.update_button_colors()
	
	# For some reason scroll pos isn't set properly unless you wait for this.
	await get_tree().process_frame
	_scroll_box.scroll_horizontal = _last_level_select_position


## Returns if the UI is currently visible.
func UI_is_visible() -> bool:
	return _level_button_container.visible


func _on_back_button_pressed() -> void:
	hide_UI()
	selection_closed.emit()


func _on_back_button_mouse_entered() -> void:
	_menu_focus_sound.play()


## Show the filters panel.
func _on_filters_button_mouse_entered() -> void:
	_menu_focus_sound.play()
	_filters_panel.show()
	_filters_button_toggle.hide()


## Close the filters panel.
func _on_filters_panel_mouse_exited() -> void:
	_filters_panel.hide()
	if UI_is_visible():
		_filters_button_toggle.show()

# Various comparator functions, for sorting levels by various properties.

## Compares 2 levels based on their name, in alphabetical order.
static func _compare_level_name(a: LevelButton, b: LevelButton) -> bool:
	return a.level_info.song_name < b.level_info.song_name


## Compares 2 levels based on their speed, from low to high.
static func _compare_level_speed(a: LevelButton, b: LevelButton) -> bool:
	return a.level_info.speed < b.level_info.speed


## Compares 2 levels based on their BPM, from low to high.
static func _compare_level_bpm(a: LevelButton, b: LevelButton) -> bool:
	return a.level_info.bpm < b.level_info.bpm


## Compares 2 levels based on their difficulty, from low to high.
static func _compare_level_difficulty(a: LevelButton, b: LevelButton) -> bool:
	return a.level_info.difficulty < b.level_info.difficulty


## Compares 2 levels based on their damage, from low to high.
static func _compare_level_damage(a: LevelButton, b: LevelButton) -> bool:
	return a.level_info.damage < b.level_info.damage


## Compares 2 levels based on their length (in seconds), from low to high.
static func _compare_level_length(a: LevelButton, b: LevelButton) -> bool:
	return a.level_info.length < b.level_info.length


## Compares 2 levels based on their bit count, from low to high.
static func _compare_level_bit_count(a: LevelButton, b: LevelButton) -> bool:
	return a.level_info.bit_count < b.level_info.bit_count

# Various level filtering buttons.

func _on_name_pressed() -> void:
	_menu_click_sound.play()
	_sort_levels_by_comparator(_compare_level_name)
	
	_filter_buttons[_current_filter_index].disabled = false
	_current_filter_index = 0
	_filter_buttons[_current_filter_index].disabled = true


func _on_difficulty_pressed() -> void:
	_menu_click_sound.play()
	_sort_levels_by_comparator(_compare_level_difficulty)
	
	_filter_buttons[_current_filter_index].disabled = false
	_current_filter_index = 1
	_filter_buttons[_current_filter_index].disabled = true


func _on_speed_pressed() -> void:
	_menu_click_sound.play()
	_sort_levels_by_comparator(_compare_level_speed)
	
	_filter_buttons[_current_filter_index].disabled = false
	_current_filter_index = 2
	_filter_buttons[_current_filter_index].disabled = true


func _on_damage_pressed() -> void:
	_menu_click_sound.play()
	_sort_levels_by_comparator(_compare_level_damage)
	
	_filter_buttons[_current_filter_index].disabled = false
	_current_filter_index = 3
	_filter_buttons[_current_filter_index].disabled = true


func _on_length_pressed() -> void:
	_menu_click_sound.play()
	_sort_levels_by_comparator(_compare_level_length)
	_filter_buttons[_current_filter_index].disabled = false
	_current_filter_index = 4
	_filter_buttons[_current_filter_index].disabled = true


func _on_bpm_pressed() -> void:
	_menu_click_sound.play()
	_sort_levels_by_comparator(_compare_level_bpm)
	
	_filter_buttons[_current_filter_index].disabled = false
	_current_filter_index = 5
	_filter_buttons[_current_filter_index].disabled = true


func _on_bit_count_pressed() -> void:
	_menu_click_sound.play()
	_sort_levels_by_comparator(_compare_level_bit_count)
	
	_filter_buttons[_current_filter_index].disabled = false
	_current_filter_index = 6
	_filter_buttons[_current_filter_index].disabled = true
